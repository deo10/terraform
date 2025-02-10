#with modules

module "web_instance" {
  source = "../ec2_module"
  ami = var.ami
  instance_type = var.instance_type
  instance_name = var.instance_name
}

output "instance_public_ip" {
  value = module.web_instance.instance_public_ip
}