pages 186-195

https://kodekloud.com/topic/playground-terraform-aws/

# Работа с Terraform: циклы, условные выражения, развертывание и подводные камни

# Условные выражения
Параметр count для условных ресурсов.
Выражения for_each и for для условных ресурсов и их вложенных блоков.
Строковая директива if для условных выражений внутри строк.

# count

modules/services/webserver-cluster/variables.tf
variable "enable_autoscaling" {
  description = "If set to true, enable auto scaling"
  type = bool
}

модуль webserver-cluster:
resource "aws_autoscaling_schedule" "scale_out_during_business_hours" {
count = var.enable_autoscaling ? 1 : 0 # attention here
scheduled_action_name = "${var.cluster_name}-scale-out-during-business-hours"
min_size = 2
max_size = 10
desired_capacity = 10
recurrence = "0 9 * * *"
autoscaling_group_name = aws_autoscaling_group.example.name
}

resource "aws_autoscaling_schedule" "scale_in_at_night" {
count = var.enable_autoscaling ? 1 : 0 # attention here
scheduled_action_name = "${var.cluster_name}-scale-in-at-night"
min_size = 2
max_size = 10
desired_capacity = 2
recurrence = "0 17 * * *"
autoscaling_group_name = aws_autoscaling_group.example.name
}

Если var.enable_autoscaling равно true, параметру count для каждого из ресурсов aws_autoscaling_schedule будет присвоено значение 1, поэтому оба они будут созданы в единственном экземпляре. Если var.enable_autoscaling равно false, параметру count для каждого из ресурсов aws_autoscaling_schedule будет присвоено значение 0, поэтому ни один из них создан не будет. Это именно та условная логика, которая нам нужна!

Дев окружение live/stage/services/webserver-cluster/main.tf: выключим масштабирование, присвоив enable_autoscaling значение false:

module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"
  
  cluster_name = "webservers-stage"
  db_remote_state_bucket = "(ИМЯ_ВАШЕЙ_КОРЗИНЫ)"
  db_remote_state_key = "stage/data-stores/mysql/terraform.tfstate"
  
  instance_type = "t2.micro"
  min_size = 2
  max_size = 2
  enable_autoscaling = false
}

в проде live/prod/services/webserver-cluster/main.tf: включим масштабирование, присвоив enable_autoscaling значение true:
module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"

  cluster_name = "webservers-prod"
  db_remote_state_bucket = "(ИМЯ_ВАШЕЙ_КОРЗИНЫ)"
  db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate"

  instance_type = "m4.large"
  min_size = 2
  max_size = 10
  enable_autoscaling = true

  custom_tags = {
    Owner = "team-foo"
    ManagedBy = "terraform"
  }
}

# if-else

variable "give_neo_cloudwatch_full_access" {
  description = "If true, neo gets full access to CloudWatch"
  type = bool
}

resource "aws_iam_user_policy_attachment" "neo_cloudwatch_full_access" {
  count = var.give_neo_cloudwatch_full_access ? 1 : 0
  user = aws_iam_user.example[0].name
  policy_arn = aws_iam_policy.cloudwatch_full_access.arn
}
resource "aws_iam_user_policy_attachment" "neo_cloudwatch_read_only" {
  count = var.give_neo_cloudwatch_full_access ? 0 : 1
  user = aws_iam_user.example[0].name
  policy_arn = aws_iam_policy.cloudwatch_read_only.arn
}

Этот код содержит два ресурса aws_iam_user_policy_attachment. У первого, который выдает полный доступ к CloudWatch, есть условное выражение. Если var.give_neo_cloudwatch_full_access равно true, оно возвращает 1, если нет — 0 (это ветвь if). Условное выражение второго ресурса, который выдает доступ на чтение, делает все наоборот: если var.give_neo_cloudwatch_full_access равно true, оно возвращает 0, если нет — 1 (это ветвь else).

output "neo_cloudwatch_policy_arn" {
  value = one(concat(
    aws_iam_user_policy_attachment.neo_cloudwatch_full_access[*].policy_arn,
    aws_iam_user_policy_attachment.neo_cloudwatch_read_only[*].policy_arn
  ))
}

В зависимости от результата условия if/else, один из атрибутов, neo_cloudwatch_full_access или neo_cloudwatch_read_only, будет иметь пустое значение, а другой — содержать один элемент, поэтому, объединив их, вы получите список с одним элементом и функция one вернет этот элемент. Этот код сохранит работоспособность, как бы ни изменилось условие if/else.

# Условная логика с использованием выражений for_each и for

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

Вложенное выражение for циклически перебирает var.custom_tags, переводя каждое значение в верхний регистр (например, для однородности), и использует
условную логику, чтобы отфильтровать любой параметр key, равный Name, поскольку модуль устанавливает свой собственный тег Name. Фильтрация значений в выражении for позволяет реализовать произвольную условную логику.

# Условные выражения с использованием строковой директивы if

output "for_directive_index_if_strip" {
  value = <<EOF
%{~ for i, name in var.names ~}
${name}%{ if i < length(var.names) - 1 }, %{ endif }
%{~ endfor ~}
EOF
}

$ terraform apply
(...)
Outputs:
for_directive_index_if_strip = "neo, trinity, morpheus"

---
output "for_directive_index_if_else_strip" {
  value = <<EOF
%{~ for i, name in var.names ~}
${name}%{ if i < length(var.names) - 1 }, %{ else }.%{ endif }
%{~ endfor ~}
EOF
}

$ terraform apply
(...)
Outputs:
for_directive_index_if_else_strip = "neo, trinity, morpheus."

