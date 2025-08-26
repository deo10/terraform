
# AWS region
variable "region" {
  description = "AWS region to deploy resources"
  default     = "us-east-1"
}

# VPC and subnet CIDR blocks (parameterized for flexibility)
variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  description = "CIDR block for the public subnet"
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  description = "CIDR block for the private subnet"
  default     = "10.0.2.0/24"
}


# CIDR block allowed for SSH (must be set to your real public IP)
variable "ssh_allowed_cidr" {
  description = "CIDR blocks that are allowed to access the instance via SSH (e.g., 203.0.113.4/32)"
  default     = "YOUR_PUBLIC_IP/32" # CHANGE THIS to your real public IP before applying

  validation {
    condition     = can(regex("^(?:[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}\\.[0-9]{1,3}/32)$", var.ssh_allowed_cidr)) && var.ssh_allowed_cidr != "YOUR_PUBLIC_IP/32"
    error_message = "You must set ssh_allowed_cidr to your real public IP in CIDR notation (e.g., 203.0.113.4/32)."
  }
}

provider "aws" {
  region = var.region
  # Credentials should be provided via environment variables or a shared credentials file for security.
}

# Create a VPC

### Main VPC
resource "aws_vpc" "main_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Main VPC"
  }
}

### Network ACL for public subnet (allow SSH, HTTP, HTTPS, ephemeral; deny all else)
resource "aws_network_acl" "public_nacl" {
  vpc_id = aws_vpc.main_vpc.id

  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = var.ssh_allowed_cidr
    from_port  = 22
    to_port    = 22
  }
  ingress {
    rule_no    = 110
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }
  ingress {
    rule_no    = 120
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }
  ingress {
    rule_no    = 130
    protocol   = "tcp"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 1024
    to_port    = 65535
  }
  # Deny all else by default
  tags = {
    Name = "Public NACL"
  }
}

### Network ACL for private subnet (allow all egress, restrict ingress)
resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.main_vpc.id

  egress {
    rule_no    = 100
    protocol   = "-1"
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }
  ingress {
    rule_no    = 100
    protocol   = "tcp"
    action     = "allow"
    cidr_block = aws_subnet.public_subnet.cidr_block
    from_port  = 3306
    to_port    = 3306
  }
  # Deny all else by default
  tags = {
    Name = "Private NACL"
  }
}


### Public subnet for EC2 instance
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr
  map_public_ip_on_launch = true
  tags = {
    Name = "Public Subnet"
  }
}


### Private subnet for internal resources (e.g., database)
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.private_subnet_cidr
  map_public_ip_on_launch = false
  tags = {
    Name = "Private Subnet"
  }
}

### Internet Gateway for VPC (enables internet access for public subnet)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "Main Internet Gateway"
  }
}

### Security group for EC2 instance (allows SSH only from your IP)
resource "aws_security_group" "ssh_security_group" {
  name        = "ssh_security_group"
  description = "Allow SSH inbound traffic"
  vpc_id      = aws_vpc.main_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SSH Access"
  }
}




### Route table for the public subnet (routes 0.0.0.0/0 to IGW)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}

### Associate public subnet with its route table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

### Route table for the private subnet (no internet access by default)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "Private Route Table"
  }
}

### Associate private subnet with its route table
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}


### EC2 instance in the public subnet
resource "aws_instance" "web" {
  ami                         = data.aws_ami.latest_ami.id
  instance_type               = "t2.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.ssh_security_group.id]
  associate_public_ip_address = true
  tags = {
    Name = "Public EC2 Instance"
  }
}




### Data source to get the latest Amazon Linux 2 AMI
data "aws_ami" "latest_ami" {
  most_recent = true
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  owners = ["amazon"]
}

### Associate NACLs with subnets
resource "aws_network_acl_association" "public_nacl_assoc" {
  network_acl_id = aws_network_acl.public_nacl.id
  subnet_id      = aws_subnet.public_subnet.id
}

resource "aws_network_acl_association" "private_nacl_assoc" {
  network_acl_id = aws_network_acl.private_nacl.id
  subnet_id      = aws_subnet.private_subnet.id
}

### Output key information after apply
output "ec2_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.web.public_ip
}

output "public_subnet_id" {
  description = "ID of the public subnet"
  value       = aws_subnet.public_subnet.id
}

output "private_subnet_id" {
  description = "ID of the private subnet"
  value       = aws_subnet.private_subnet.id
}

