data "terraform_remote_state" "level1" {
  backend = "s3" {
  bucket = "my-tf-test-bucket-panov"
  key    = "level1.tfstate"
  region = "us-east-1"
  }
}