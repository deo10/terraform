pages 195-211

https://kodekloud.com/topic/playground-terraform-aws/

# Развертывание с нулевым временем простоя

aws_autoscaling_group в файле modules/services/webserver-cluster/main.tf
(limit - не работает с политиками размеров от времени - смотри вариант в след главе)
resource "aws_autoscaling_group" "example" {
    #Создаем явную зависимость от имени конфигурации запуска,
    #чтобы вместе с ней заменялась и группа ASG
    name = "${var.cluster_name}-${aws_launch_configuration.example.name}"
    
    launch_configuration = aws_launch_configuration.example.name
    vpc_zone_identifier = data.aws_subnet_ids.default.ids
    target_group_arns = [aws_lb_target_group.asg.arn]
    health_check_type = "ELB"
    
    min_size = var.min_size
    max_size = var.max_size
    
    #Ждем, пока проверку работоспособности не пройдет как минимум
    #столько серверов, прежде чем считать завершенным развертывание ASG
    min_elb_capacity = var.min_size
    
    #При замене этой группы ASG сначала создаем ее новую версию,
    #и только потом удаляем старую
    lifecycle {
      create_before_destroy = true # ! важно !
    }

    tag {
      key = "Name"
      value = var.cluster_name
      propagate_at_launch = true
    }

    dynamic "tag" {
      for_each = {
        for key, value in var.custom_tags:
          key => upper(value)
        if key != "Name"
    }

    content {
      key = tag.key
      value = tag.value
      propagate_at_launch = true
    }
  }
}

У этого подхода есть еще одно преимущество: если во время развертывания что-то пойдет не так, Terraform автоматически откатит все назад. Например, если в версии v2 приложения обнаружится ошибка, из-за которой оно не сможет загрузиться, серверы из новой группы ASG не будут зарегистрированы в ALB. Terraform будет ждать регистрации min_elb_capacity серверов из ASG v2 на протяжении отрезка времени длиной wait_for_capacity_timeout (по умолчанию 10 минут). После этого посчитает развертывание неудавшимся, удалит серверы v2 ASG и завершит работу с ошибкой (тем временем версия v1 приложения продолжит нормально работать в оригинальной группе ASG).

# Подводные камни Terraform

Terraform требует, чтобы count и for_each вычислялись на этапе планирования, до создания или изменения каких-либо ресурсов. Это означает, что count и for_each могут ссылаться на литералы, переменные, источники данных и даже списки ресурсов (при условии, что их длину можно определить во время планирования), но не на вычисляемые выходные переменные ресурса.

Рекомендованый вариант с ASG с нулевым временем простоя
resource "aws_autoscaling_group" "example" {
  name = var.cluster_name
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnets.default.ids
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

  min_size = var.min_size
  max_size = var.max_size

  #Использовать instance_refresh для накатывания изменений на ASG
  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
  }
}

Загляните в документацию по ресурсам, которые вы используете, и по возможности используйте встроенные решения!

