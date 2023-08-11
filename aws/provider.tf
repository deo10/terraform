#Making tf state remote on S3, bucket created manually
terraform {
  backend "s3" {
    bucket = "bucket_name"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

# Define the provider (AWS in this case)
provider "aws" {
  region = "us-east-1" # Change to your desired region
}