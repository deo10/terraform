# Task - Update main.tf to configure connection settings for the EC2 instance

# Include the necessary connection block with the following arguments:
# type: ssh
# user: ec2-user
# private_key: Path to my-terraform-key key file 
# host: Public IP of the instance i.e. self-IP

# The following commands, when run in succession, will install nginx on the instance:
# sudo yum update -y
# sudo yum install -y nginx
# sudo systemctl start nginx
# sudo systemctl enable nginx

resource "aws_security_group" "allow_ssh_http" {
  name_prefix = "allow_ssh_http"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "ec2_instance" {
  ami           = "ami-06c68f701d8090592" 
  instance_type = "t2.micro"
  key_name      = "my-terraform-key"

  vpc_security_group_ids = [aws_security_group.allow_ssh_http.id]

  associate_public_ip_address = true

  provisioner "remote-exec" {
    inline = [
      "sudo yum update -y",
      "sudo yum install -y nginx",
      "sudo systemctl start nginx",
      "sudo systemctl enable nginx",
    ]

    connection {
      type        = "ssh"
      user       = "ec2-user"
      private_key = file("/root/my-terraform-key.pem")
      host       = self.public_ip
    }
  }

  tags = {
    Name = "NginxServer"
  }
}

output "instance_public_ip" {
  value = aws_instance.ec2_instance.public_ip
}
