data "aws_ami" "amazonlinux" { #looking for region specific ami and filter on it
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn2-ami-kernel-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "public" {
  count = 2

  ami                         = data.aws_ami.amazonlinux.id #using data resource to get region specific ami id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  key_name                    = "main" #key pair name (created manually)
  vpc_security_group_ids      = [aws_security_group.public.id]
  subnet_id                   = data.terraform_remote_state.level1.outputs.public_subnet_id[count.index] #using existing subnet from outputs in level1



  tags = {
    Name = "${var.env_code}-public" #using env var from variables.tf
  }
}

resource "aws_security_group" "public" {
  name        = "${var.env_code}-public"
  description = "Allow inbound traffic"
  vpc_id      = data.terraform_remote_state.level1.ouputs.vpc_id #using vpc from level1 outputs

  ingress {
    description = "SSH from public"
    from_port   = 22 #Adding a port range from to
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["109.201.178.180/32"] #check and add your public IP here 
  }

  ingress {
    description     = "Webserver access HTTP from public"
    from_port       = 80 #Adding a port range from to
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.load-balancer.id]
  }

  ingress {
    description = "Webserver access HTTP from loadbalancer"
    from_port   = 80 #Adding a port range from to
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #open widly
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_code}-public"
  }
}

resource "aws_instance" "private" {
  count = 2

  ami                    = data.aws_ami.amazonlinux.id
  instance_type          = "t3.micro"
  key_name               = "main" #key pair name (created manually)
  vpc_security_group_ids = [aws_security_group.private.id]
  subnet_id              = data.terraform_remote_state.level1.outputs.private_subnet_id[count.index] #using existing subnet from aws_vpc
  user_data              = file["user_data.sh"]                                                      #apply sh script on ec2 instance


  tags = {
    Name = "${var.env_code}-private" #using env var from variables.tf
  }
}
resource "aws_security_group" "private" {
  name        = "${var.env_code}-private"
  description = "Allow VPC traffic"
  vpc_id      = data.terraform_remote_state.level1.ouputs.vpc_id #using vpc from level1 outputs

  ingress {
    description = "SSH from VPC"
    from_port   = 22 #Adding a port range from to
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.level1.outputs.vpc_cidr] #using VPC cidr from outputs level1
  }

  ingress {
    description     = "Webserver access HTTP from loadbalancer"
    from_port       = 80 #Adding a port range from to
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.load-balancer.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_code}-private"
  }
}
