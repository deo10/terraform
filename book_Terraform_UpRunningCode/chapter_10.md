pages 251-306

https://kodekloud.com/topic/playground-terraform-aws/
# Работа с несколькими провайдерами

terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

Region Alias issue with module:
Предупреждение: используйте псевдонимы с осторожностью. В Terraform легко использовать псевдонимы, но я бы предостерег от слишком частого
их употребления, особенно при настройке многорегиональной инфраструктуры. Одна из основных причин создания многорегиональной инфраструктуры заключается в возможности обеспечить отказоустойчивость: например, если us-east-2 выйдет из строя, то ваша инфраструктура в us-west-1 сможет продолжать работать. Но если для развертывания в обоих регионах вы используете один модуль Terraform с псевдонимами, то, когда один из этих регионов окажется недоступен, модуль не сможет подключиться к этому региону и любая попытка запустить plan или apply завершится неудачей. Поэтому, когда вам понадобится применить изменения и одновременно с этим произойдет серьезный сбой, ваш код Terraform перестанет работать.


# Создание модулей, способных работать с несколькими провайдерами.

использованиe псевдонимов конфигураций для работы модулей
terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "~> 4.0"
      configuration_aliases = [aws.parent, aws.child]
    }
  }
}

data "aws_caller_identity" "parent" {
  provider = aws.parent
}
data "aws_caller_identity" "child" {
  provider = aws.child
}

Ключевое отличие от обычных псевдонимов провайдеров заключается в том, что псевдонимы конфигурации сами по себе не создают никаких провайдеров, а вынуждают пользователей вашего модуля явно передать провайдер для каждого из ваших псевдонимов конфигурации, используя ассоциативный массив providers.

# Пример развертывания AWS/Kubernetes/Docker

elements/services/k8s-app/variables.tf:
variable "name" {
  description = "The name to use for all resources created by this module"
  type = string
}
variable "image" {
  description = "The Docker image to run"
  type = string
}
variable "container_port" {
  description = "The port the Docker image listens on"
  type = number
}
variable "replicas" {
  description = "How many replicas to run"
  type = number
}
variable "environment_variables" {
  description = "Environment variables to set for the app"
  type = map(string)
  default = {}
}

elements/services/k8s-app/main.tf:
terraform {
  required_version = ">= 1.0.0, < 2.0.0"

  required_providers {
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
}

locals {
  pod_labels = {
    app = var.name
  }
}

resource "kubernetes_deployment" "app" {
  metadata {
    name = var.name
  }
  spec {
    replicas = var.replicas

    template {
      metadata {
        labels = local.pod_labels
      }
      
      spec {
        container {
          name = var.name
          image = var.image

          port {
          container_port = var.container_port
          }

            dynamic "env" {
            for_each = var.environment_variables
            content {
              name = env.key
              value = env.value
            }
          }
        }
      }
    }
    selector {
      match_labels = local.pod_labels
    }
  }
}

resource "kubernetes_service" "app" {
  metadata {
    name = var.name
  }
  spec {
    type = "LoadBalancer"
    port {
      port = 80
      target_port = var.container_port
      protocol = "TCP"
    }
    selector = local.pod_labels
  }
}


#Ресурс kubernetes_service имеет выходной атрибут status, возвращающий последнее состояние Service.
elements/services/k8s-app/outputs.tf:
locals {
  status = kubernetes_service.app.status
}

output "service_endpoint" {
  value = try(
    "http://${local.status[0]["load_balancer"][0]["ingress"][0]["hostname"]}",
    "(error parsing hostname from status)"
  )
  description = "The K8S Service endpoint"
}


example/kubernetes-local/main.tf - run local on docker-desktop
provider "kubernetes" {
  config_path = "~/.kube/config"
  config_context = "docker-desktop"
}

module "simple_webapp" {
  source = "../../modules/services/k8s-app"
  name = "simple-webapp"
  image = "training/webapp"
  replicas = 2
  container_port = 5000
}

