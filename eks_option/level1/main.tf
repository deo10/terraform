
data "aws_availability_zones" "available" { #taking all available AZ from the region that is mentioned in provider.tf
  state = "available"
}

#creating VPC using open source modules - https://github.com/terraform-aws-modules
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name               = "${var.env_code}-vpc"
  cidr               = var.vpc_cidr
  azs                = data.aws_availability_zones.available.names[*]
  public_subnets     = var.public_cidr
  private_subnets    = var.private_cidr
  enable_nat_gateway = true

  private_subnet_tags = {
    "name"                                      = "private"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"           = "1"
  }

  public_subnet_tags = {
    "name"                                      = "public"
    "kubernetes.io/cluster/${var.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                    = "1"
  }
}

