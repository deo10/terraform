#using aws secret manager and manually created secret for RDS
data "aws_secretsmanager_secret" "rds_password" {
  name = "example"
}

data "aws_secretsmanager_secret_version" "rds_password" {
  secret_id = data.aws_secretsmanager_secret.rds_password.id
}
#password will be decoded, to decode use
locals {
  rds_password = jsondecode(data.aws_secretsmanager_secret_version.rds_password.secret_string)["password"]
}

module "rds" {
  source = "../modules/rds"

  subnet_ids            = data.terraform_remote_state.level1.outputs.private_subnet_id
  env_code              = var.env_code
  rds_password          = local.rds_password
  vpc_id                = data.terraform_remote_state.level1.outputs.vpc_id
  source_security_group = module.asg.security_group_id


}