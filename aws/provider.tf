#Making tf state remote on S3, db to lock state, both created manually
terraform {
  backend "s3" {
    bucket = "my-tf-test-bucket"
    key    = "terraform.tfstate"
    region = "us-east-1"
    dynamodb_table = "terraform-remote-state"
  }
}

# Define the provider (AWS in this case)
provider "aws" {
  region = "us-east-1" # Change to your desired region
}