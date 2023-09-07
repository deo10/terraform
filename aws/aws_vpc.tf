# Define the provider (AWS in this case)
provider "aws" {
  region = "us-east-1" # Change to your desired region
}

# Create the VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16" # Replace with your desired VPC CIDR block
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

resource "aws_subnet" "private_subnet1" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.2.0/24" # Replace with your desired private subnet CIDR block for AZ1
  availability_zone = "us-east-1a"  # Replace with your desired AZ1
}

# Create the public subnets in the second availability zone (AZ)
resource "aws_subnet" "public_subnet2" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.3.0/24" # Replace with your desired public subnet CIDR block for AZ2
  availability_zone       = "us-east-1b"  # Replace with your desired AZ2
  map_public_ip_on_launch = true
}

resource "aws_subnet" "private_subnet2" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.4.0/24" # Replace with your desired private subnet CIDR block for AZ2
  availability_zone = "us-east-1b"  # Replace with your desired AZ2
}

# Create the route tables
resource "aws_route_table" "public_route_table1" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table" "public_route_table2" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table" "private_route_table1" {
  vpc_id = aws_vpc.my_vpc.id
}

resource "aws_route_table" "private_route_table2" {
  vpc_id = aws_vpc.my_vpc.id
}

# Associate the subnets with the route tables
resource "aws_route_table_association" "public_subnet1_association" {
  subnet_id      = aws_subnet.public_subnet1.id
  route_table_id = aws_route_table.public_route_table1.id
}

resource "aws_route_table_association" "public_subnet2_association" {
  subnet_id      = aws_subnet.public_subnet2.id
  route_table_id = aws_route_table.public_route_table2.id
}

resource "aws_route_table_association" "private_subnet1_association" {
  subnet_id      = aws_subnet.private_subnet1.id
  route_table_id = aws_route_table.private_route_table1.id
}

resource "aws_route_table_association" "private_subnet2_association" {
  subnet_id      = aws_subnet.private_subnet2.id
  route_table_id = aws_route_table.private_route_table2.id
}

# Create the NAT gateways
resource "aws_nat_gateway" "nat_gateway1" {
  allocation_id = aws_eip.nat_eip1.id
  subnet_id     = aws_subnet.public_subnet1.id
}

resource "aws_nat_gateway" "nat_gateway2" {
  allocation_id = aws_eip.nat_eip2.id
  subnet_id     = aws_subnet.public_subnet2.id
}

# Create the Elastic IPs for the NAT gateways
resource "aws_eip" "nat_eip1" {
  domain = "vpc"
}

resource "aws_eip" "nat_eip2" {
  domain = "vpc"
}
