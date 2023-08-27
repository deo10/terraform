#Making tf state remote on S3, db to lock state, both created by files in remote-state folder
terraform {
  backend "s3" {
    bucket         = "my-tf-test-bucket"
    key            = "level2.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-remote-state"
  }
}

# Define the provider (AWS in this case)
provider "aws" {
  region = "us-east-1" # Change to your desired region
}