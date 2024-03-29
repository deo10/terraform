
data "aws_availability_zones" "available" { #taking all available AZ from the region that is mentioned in provider.tf
  state = "available"
}

#creating VPC using modules
module "vpc" {
  source = "../modules/vpc"

  env_code           = var.env_code
  vpc_cidr           = var.vpc_cidr
  public_cidr        = var.public_cidr
  private_cidr       = var.private_cidr
  availability_zones = data.aws_availability_zones.available.names
}

