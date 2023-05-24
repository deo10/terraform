provider "null" {}

resource "null_resource" "create_file" {
  provisioner "local-exec" {
    command = "echo 'Hello, Terraform!' > ${var.file_path}"
    interpreter = ["cmd", "/C"]
  }

  triggers = {
    file_path = var.file_path
  }
}

variable "file_path" {
  description = "Path to the file"
  default     = "C:/Users/Andrei_Panov/Documents/code/terraform/file.txt"
}