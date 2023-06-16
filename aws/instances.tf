resource "aws_instance" "public" {
  ami                         = data.aws_ami.amzn-linux-2023-ami.id
  instance_type               = "t3.micro"
  associate_public_ip_address = true
  key_name                    = "main"
  vpc_security_group_ids      = []
  subnet_id                   = [aws_subnet.public[0].id] #using existing subnet


  tags = {
    Name = "${var.env_code}-public" #using env var from variables.tf
  }
}

resource "aws_security_group" "public" {
  name        = "${var.env_code}-public"
  description = "Allow inbound traffic"
  vpc         = aws_vpc.main.id

  ingress {
    description = "SSH from public"
    from_port   = 22 #Adding a port range from to
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["109.201.178.180/32"] #check and add your public IP here 
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