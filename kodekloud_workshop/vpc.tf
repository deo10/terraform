# Create the VPC
resource "aws_vpc" "KK_VPC" {
  cidr_block = "10.0.0.0/16" # Replace with your desired VPC CIDR block
}

