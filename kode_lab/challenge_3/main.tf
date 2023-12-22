#In this challenge we will implement a simple EC2 instance with some preinstalled packages.
#Utilize /root/terraform-challenges/project-citadel directory to store your Terraform configuration files.

#Amazon Web Services (AWS) provider have been configured already to interact with the many resources supported by AWS.

#task
#Create a terraform key-pair citadel-key with key_name citadel.
#Upload the public key ec2-connect-key.pub to the resource.
#You may use the file function to read the the public key at /root/terraform-challenges/project-citadel/.ssh

#citadel
#AMI: ami-06178cf087598769c, use variable named ami
#Region: eu-west-2, use variable named region
#Instance Type: m5.large, use variable named instance_type
#Elastic IP address attached to the EC2 instance

#task #2
#Create a local-exec provisioner for the eip resource and use it to print the attribute called public_dns
# to a file /root/citadel_public_dns.txt on the iac-server

#taks #3
#Install nginx on citadel instance, make use of the user_data argument.
#Using the file function or by making use of the heredoc syntax,
# use the script called install-nginx.sh as the value for the user_data argument.


resource "aws_key_pair" "citadel-key" {
  key_name   = "citadel"
  public_key = file("/root/.ssh/citadel.pub")
}

resource "aws_security_group" "public" {
  name        = "SG-SSH"
  description = "Allow ssh traffic"
  vpc_id      = aws_vpc.my_vpc.id
  
  ingress {
    description = "SSH from VPC"
    from_port   = 22 #Adding a port range from to
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 
  
  # Outbound rules for ICMP traffic
  egress {
    from_port   = 8 // ICMP Type 8 (ping) - Echo Request
    to_port     = 0
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"] // Allow ICMP egress traffic to all destinations
  }

  # Outbound rules for all TCP traffic
  egress {
    from_port   = 0 // Allow all source ports
    to_port     = 65535 // Allow all destination ports
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] // Allow all TCP egress traffic to all destinations
  }

  tags = {
    Name = "SG-SSH-ICMP-TCP"
  }
}

resource "aws_instance" "citadel" {
  ami           = var.ami
  instance_type = var.instance_type
  key_name      = aws_key_pair.citadel-key.key_name
  vpc_security_group_ids = [aws_security_group.private.id]
  subnet_id = aws_subnet.public_subnet1.id
  user_data     = file("install-nginx.sh")

  tags = {
    Name = "citadel"
  }
}

resource "aws_eip" "citadel_eip" {
  vpc      = true
  instance = aws_instance.citadel.id
  
  provisioner "local-exec" {
    command = "echo ${self.public_dns} >> /root/citadel_public_dns.txt"
  }
}