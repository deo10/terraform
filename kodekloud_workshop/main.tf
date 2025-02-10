# create ec2 instance use an existing AMI ID (ami-01b799c439fd5516a)
# for the EC2 instance, and set the instance type to t2.micro.
# The instance should be launched in the us-east-1 region, and should be assigned to the default VPC.

provider "aws" {
  region = "us-east-1"
  access_key = ""
  secret_key = ""
}

# Create the EC2 with variables
resource "aws_instance" "web" {
  instance_type = var.instance_type
  ami = var.ami
}

# Run terraform init to download the AWS provider plugin

#Now, create an S3 bucket for remote state storage.
#Name the bucket my-terraform-state-[your-name-or-unique-string], ensuring it's a globally unique name.
#Replace [your-name-or-unique-string] with your name or a unique string. Enable versioning and keep the ACL as private.

resource "aws_s3_bucket" "terraform_state" {
  bucket = "my-terraform-state-andreipanov"
  versioning {
    enabled = true
  }
  acl = "private"
}

# Configure terraform to use the S3 bucket for state management.
# Add the required block in a new file called backend.tf.
# For key, add terraform-state-file.

terraform {
  backend "s3" {
    bucket = "my-terraform-state-andreipanov"
    key    = "terraform-state-file"
    region = "us-east-1"
    }
}


# Store sensitive information securely using AWS Secrets Manager by creating a new secret.
# Name the secret my-database-password and store a value "YourSecurePassword".
# Note: Create this secret using the AWS CLI.

#-> aws secretsmanager create-secret --name my-database-password --secret-string "YourSecurePassword"


# Using terraform, create an RDS database resource called my_secret_db with the following specs:

# identifier: rds-db-instance
# allocated_storage: 20
# storage_type: gp2
# engine: mysql
# engine_version: 5.7
# instance_class: db.t3.micro
# username: admin
# Utilize the data source aws_secretsmanager_secret_version to retrieve the secret my-database-password
# and use it in the resource as password.

# Initialize the repository, generate an execution plan and apply the configuration.

# not required as present on provider.tf
# provider "aws" {
#   region = "us-east-1"
#   access_key = ""
#   secret_key = ""
# }

data "aws_secretsmanager_secret_version" "my_secret_db" {
    secret_id = "my-database-password"
}

resource "aws_db_instance" "rds-db-instance" {
  identifier = "rds-db-instance"
  allocated_storage = 20
  storage_type = "gp2"
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t3.micro"
  username = "admin"
  password = data.aws_secretsmanager_secret_version.my_secret_db.secret_string
}

# Run terraform init to move the state file to the S3 bucket.
