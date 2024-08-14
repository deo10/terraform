pages 166-186

https://kodekloud.com/topic/playground-terraform-aws/

# Работа с Terraform: циклы, условные выражения, развертывание и подводные камни

# Циклы
# count

resource "aws_iam_user" "example" {
  count = 3 # how many items create
  name = "neo.${count.index}" #required to add unique id
}

updating to the next level

variables.tf:
variable "user_names" {
  description = "Create IAM users with these names"
  type = list(string)
  default = ["neo", "trinity", "morpheus"]
}

code.tf:
resource "aws_iam_user" "example" {
  count = length(var.user_names) #taking count from var -> variables.tf
  name = var.user_names[count.index] #adding required id using var
}

possible to use in modules

module "users" {
  source = "../../../modules/landing-zone/iam-user"
  count = length(var.user_names)
  user_name = var.user_names[count.index]
}

Important:
Count is not good for making changes, as resources will be re-created if the order changed.
Cannot apply in 2nd level of included block.

# for_each

resource "aws_iam_user" "example" {
  for_each = toset(var.user_names)
  name = each.value
}

toset function, moves var.user_names into array. because for_each support array and associative arrays only for resources.

example with tags:

variable "custom_tags" {
  description = "Custom tags to set on the Instances in the ASG"
  type = map(string)
  default = {}
}

module "webserver_cluster" {
  source = "../../../../modules/services/webserver-cluster"
  
  cluster_name = "webservers-prod"
  db_remote_state_bucket = "(ИМЯ_ВАШЕЙ КОРЗИНЫ)"
  db_remote_state_key = "prod/data-stores/mysql/terraform.tfstate"
  
  instance_type = "m4.large"
  min_size = 2
  max_size = 10
  
  custom_tags = {
    Owner = "team-foo"
    ManagedBy = "terraform"
  }
}

resource "aws_autoscaling_group" "example" {
  launch_configuration = aws_launch_configuration.example.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"
  min_size = var.min_size
  max_size = var.max_size
  
  tag {
    key = "Name"
    value = var.cluster_name
    propagate_at_launch = true
  }
  
  dynamic "tag" {
    for_each = var.custom_tags
  
    content {
      key = tag.key
      value = tag.value
      propagate_at_launch = true
    }
  }
}

# for

output "upper_names" {
  value = [for name in var.names : upper(name)]
}

result
upper_names = [
  "NEO",
  "TRINITY",
  "MORPHEUS",
]

output "short_upper_names" {
  value = [for name in var.names : upper(name) if length(name) < 5]
}

result
short_upper_names = [
  "NEO",
]


variable "hero_thousand_faces" {
  description = "map"
  type = map(string)
  default = {
    neo = "hero"
    trinity = "love interest"
    morpheus = "mentor"
  }
}
output "bios" {
  value = [for name, role in var.hero_thousand_faces : "${name} is the ${role}"]
}

result
bios = [
"morpheus is the mentor",
"neo is the hero",
"trinity is the love interest",
]

output "upper_roles" {
  value = {for name, role in var.hero_thousand_faces : upper(name) => upper(role)}
}

result
upper_roles = {
"MORPHEUS" = "MENTOR"
"NEO" = "HERO"
"TRINITY" = "LOVE INTEREST"
}

