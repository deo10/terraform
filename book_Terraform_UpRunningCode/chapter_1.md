pages 81-95

# creating config for web-server in AWS
Prerequisite
Install the AWS CLI by following the instructions in the AWS documentation:
https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

Configure the AWS CLI with your AWS credentials using the aws configure command. This will prompt you to enter your AWS Access Key ID, Secret Access Key, AWS Region, and default output format.

Linux:
$ export AWS_ACCESS_KEY_ID=(ID access_key)
$ export AWS_SECRET_ACCESS_KEY=(private_key)
Windows:
$ set AWS_ACCESS_KEY_ID=(ID access_key)
$ set AWS_SECRET_ACCESS_KEY=(private_key)


provider.tf

provider "aws" {
  region = "us-east-2"
}

variables.tf

variable "server_port" {
  description = "The port the server will use for HTTP requests"
  type = number
  default = 8080
}

main.tf

resource "aws_security_group" "instance" {
  name = "terraform-example-instance"
  ingress {
    from_port = var.server_port
    to_port = var.server_port
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "example" {
  ami                    = "ami-0fb653ca2d3203ac1"
  instance_type          = "t2.micro"
  vpc_security_group_ids = [aws_security_group.instance.id]

  user_data = <<-EOF
       #!/bin/bash
       echo "Hello, World" > index.html
       nohup busybox httpd -f -p ${var.server_port} &
       EOF
  user_data_replace_on_change = true
  
  tags = {
    Name = "terraform-example"
  }
}

output "public_ip" {
  value = aws_instance.example.public_ip
  description = "The public IP address of the web server"
}