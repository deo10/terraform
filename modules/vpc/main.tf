# Create the VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_cidr # will create vpc cidr from variables.tf

  tags = {
    Name = var.env_code # will create tag from variables.tf
  }
}

# Create the internet gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = var.env_code # will create tag from variables.tf
  }
}

# Create the public subnets
resource "aws_subnet" "public" {
  count = length(var.public_cidr) # will count number of values in locals-public_cidr

  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.public_cidr[count.index]        # will use values in locals-public_cidr
  availability_zone       = var.availability_zones[count.index] # will use values from module config
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env_code}-public${count.index + 1}" # will create tag env_code+public+number
  }
}

# Create the private subnets
resource "aws_subnet" "private" {
  count = length(var.private_cidr)

  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.private_cidr[count.index]       # will use values in locals-private_cidr
  availability_zone = var.availability_zones[count.index] # will use values from module config

  tags = {
    Name = "${var.env_code}-private${count.index + 1}"
  }
}

# Create the route tables
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_igw.id
  }

  tags = {
    Name = "${var.env_code}-public${count.index + 1}" # will create tag env_code+public+number
  }
}

resource "aws_route_table" "private" {
  count  = length(var.private_cidr)
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway[count.index].id
  }

  tags = {
    Name = "${var.env_code}-private${count.index + 1}"
  }
}

# Associate the subnets with the route tables
resource "aws_route_table_association" "public" {
  count = length(var.public_cidr)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id

  tags = {
    Name = "${var.env_code}-public${count.index + 1}"
  }
}

resource "aws_route_table_association" "private" {
  count = length(var.private_cidr)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id

  tags = {
    Name = "${var.env_code}-private${count.index + 1}"
  }
}

# Create the Elastic IPs for the NAT gateways
resource "aws_eip" "nat" {
  count = length(var.public_cidr)

  vpc = true

  tags = {
    Name = "${var.env_code}-eip${count.index + 1}"
  }
}

# Create the NAT gateways
resource "aws_nat_gateway" "nat_gateway" {
  count = length(var.public_cidr)

  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.env_code}-nat${count.index + 1}"
  }
}