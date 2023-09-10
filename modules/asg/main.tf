#creating EC2 instances

resource "aws_security_group" "public" {
  name        = "${var.env_code}-public"
  description = "Allow inbound traffic"
  vpc_id      = var.vpc_id #using vpc from module config

  /*   ingress {
    description = "SSH from public"
    from_port   = 22 #Adding a port range from to
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["109.201.178.180/32"] #check and add your public IP here 
  } */ #commented as a part of implementing Session Manager

  ingress {
    description     = "Webserver access HTTP from public"
    from_port       = 80 #Adding a port range from to
    to_port         = 80
    protocol        = "tcp"
    security_groups = var.lb_security_group_id
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

  ami                    = var.ami_id
  instance_type          = "t3.micro"
  key_name               = "main" #key pair name (created manually)
  vpc_security_group_ids = [aws_security_group.private.id]
  subnet_id              = var.private_subnet_id[count.index]  #using existing subnet from vpc module
  user_data              = file("${path.module}/user_data.sh") #apply sh script on ec2 instance


  tags = {
    Name = "${var.env_code}-private" #using env var from variables.tf
  }
}
resource "aws_security_group" "private" {
  name        = "${var.env_code}-private"
  description = "Allow VPC traffic"
  vpc_id      = var.vpc_id #using vpc from module config

  /* ingress {
    description = "SSH from VPC"
    from_port   = 22 #Adding a port range from to
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [data.terraform_remote_state.level1.outputs.vpc_cidr] #using VPC cidr from outputs level1
  } */ # commented as a part of implementing Session Manager

  ingress {
    description     = "Webserver access HTTP from loadbalancer"
    from_port       = 80 #Adding a port range from to
    to_port         = 80
    protocol        = "tcp"
    security_groups = var.lb_security_group_id
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

#Autoscaling

resource "aws_launch_configuration" "main" {
  name_prefix          = "${var.env_code}-private"
  image_id             = var.ami_id
  instance_type        = "t2.micro"
  security_groups      = [aws_security_group.private]
  user_data            = file("${path.module}/user_data.sh")
  iam_instance_profile = aws_iam_instance_profile.main.name #as a part of implementing Session Manager
  #key_name        = "main" #as a part of implementing Session Manager

  #adding tags on instances that is lauching
   tags = [
    {
      key                 = "Name"
      value               = var.env_code
      propagate_at_launch = true
    },
    # Add more tags if needed
  ]
}

resource "aws_autoscaling_group" "main" {
  name             = "${var.env_code}-private"
  min_size         = 2
  desired_capacity = 2
  max_size         = 4

  target_group_arns    = var.target_group_arn #all instances are under loadbalancer
  launch_configuration = aws_launch_configuration.main.name
  vpc_zone_identifier  = var.private_subnet_id #created in private subnet 
}


#IAM part
resource "aws_iam_role" "main" {
  name                = var.env_code
  managed_policy_arns = ["arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"]
  assume_role_policy  = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
  EOF  
}


resource "aws_iam_instance_profile" "main" {
  name = var.env_code
  role = aws_iam_role.main.name
}