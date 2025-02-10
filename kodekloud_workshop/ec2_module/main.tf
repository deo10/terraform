resource "aws_instance" "this" {
  instance_type = var.instance_type
  ami = var.ami

  tags = {
    Name = var.instance_name
  }
}

output "instance_public_ip" {
  value = aws_instance.this.public_ip
}