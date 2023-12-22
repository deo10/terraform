create
provider.tf -- edit part for default settings
variables.tf - edit part for instance and ami AMI ID - check in AWS EC2 web console

terraform init

create ssh key locally
ssh-keygen -t rsa -b 2048 -f ~/.ssh/citadel

chmod 400 ~/.ssh/citadel

create
main.tf - change path to ssh key

terraform plan
terraform apply

ssh -i ~/.ssh/citadel ec2-user@public-ip
