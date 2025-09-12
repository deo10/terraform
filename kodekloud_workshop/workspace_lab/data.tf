#Create a file named data.tf which defines an output called nontf_instance_ip.
#The value of the output should be the display name of this EC2 instance.

data "aws_instance" "new_instance" {
  instance_id = "<ID_from_console>" # How to get it: https://docs.aws.amazon.com/cli/latest/reference/ec2/describe-instances.html
}

output "nontf_instance_ip" {
  value = data.aws_instance.new_instance.public_ip
}
