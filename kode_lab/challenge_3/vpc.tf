# Create the VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16" # Replace with your desired VPC CIDR block

  tags = {
    Name = var.env_code # will create tag from variables.tf
  }
}

# Create the internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create the public subnets in the first availability zone (AZ)
resource "aws_subnet" "public_subnet1" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.1.0/24" # Replace with your desired public subnet CIDR block for AZ1
  availability_zone       = "us-east-1a"  # Replace with your desired AZ1
  map_public_ip_on_launch = true
}

# Create the route tables
resource "aws_route_table" "public_route_table1" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}


# Associate the subnets with the route tables
resource "aws_route_table_association" "public_subnet1_association" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_route_table1.id
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
    Name = "${var.env_code}-SG-SSH-ICMP-TCP"
  }
}