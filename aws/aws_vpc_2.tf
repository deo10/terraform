# Define the provider (AWS in this case)
provider "aws" {
  region = "us-east-1"  # Change to your desired region
}

locals {
  public_cidr = ["10.0.0.0/24", "10.0.1.0/24"]
  private_cidr = ["10.0.2.0/24", "10.0.3.0/24"]
  availability_zones = ["us-east-1a", "us-east-1b"]
}

# Create the VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"  # Replace with your desired VPC CIDR block
}

# Create the internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
}

# Create the public subnets
resource "aws_subnet" "public" {
  count                   = 2

  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = local.public_cidr[count.index]  # Replace with your desired public subnet CIDR block for AZ1
  availability_zone       = local.availability_zones[count.index]  # Replace with your desired AZ1
  map_public_ip_on_launch = true

  tags = {
    Name = "public${count.index+1}"
  }
}

# Create the private subnets
resource "aws_subnet" "private" {
  count                   = 2

  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = local.private_cidr[count.index]  # Replace with your desired private subnet CIDR block for AZ1
  availability_zone       = local.availability_zones[count.index]  # Replace with your desired AZ1

  tags = {
    Name = "private${count.index+1}"
  }
}

# Create the route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }
}

resource "aws_route_table" "private" {
  count = 2
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
  }
}

# Associate the subnets with the route tables
resource "aws_route_table_association" "public" {
  count          = 2

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  count          = 2

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Create the Elastic IPs for the NAT gateways
resource "aws_eip" "nat" {
  count = 2
  
  vpc   = true
}

# Create the NAT gateways
resource "aws_nat_gateway" "nat_gateway" {
  count         = 2

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id
}

