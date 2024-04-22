pages 109-142

https://kodekloud.com/topic/playground-terraform-aws/

# Working with terraform state

creating S3 backet for state file
create new tf file in the separate folder (level0)

First run comment section for moving state
run terraform init -reconfigure 
run 2nd time with moving state code

main.tf
provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "terraform_state_panov" {
  bucket = "panovandreibucket123"
  # Предотвращаем случайное удаление этой корзины S3
  lifecycle {
    prevent_destroy = true
  }
}

# Включить управление версиями, чтобы иметь возможность
# видеть всю историю изменения файлов состояния
resource "aws_s3_bucket_versioning" "enabled" {
  bucket = aws_s3_bucket.terraform_state_panov.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Включить шифрование на стороне сервера
resource "aws_s3_bucket_server_side_encryption_configuration" "default" {
  bucket = aws_s3_bucket.terraform_state_panov.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Явно заблокировать публичный доступ к корзине S3
resource "aws_s3_bucket_public_access_block" "public_access" {
  bucket                  = aws_s3_bucket.terraform_state_panov.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# создать таблицу DynamoDB, которая будет использоваться для блокировки.
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-up-and-running-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  attribute {
    name = "LockID"
    type = "S"
  }
}

# moving state to the S3
terraform {
  backend "s3" {
# Укажите здесь имя своей корзины!
  bucket = "panovandreibucket123"
  key = "global/s3/terraform.tfstate"
  region = "us-east-1"
# Укажите здесь имя своей таблицы DynamoDB!
#  dynamodb_table = "terraform-up-and-running-locks"
#  encrypt = true
  }
}

output "s3_bucket_arn" {
  value       = aws_s3_bucket.terraform_state_panov.arn
  description = "The ARN of the S3 bucket"
}
output "dynamodb_table_name" {
  value       = aws_dynamodb_table.terraform_locks.name
  description = "The name of the DynamoDB table"
}