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
