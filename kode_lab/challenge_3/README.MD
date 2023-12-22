create
provider.tf -- edit part for default settings
variables.tf - edit part for instance and ami ID - check in AWS EC2 web console

terraform init

create ssh key locally
ssh-keygen -t rsa -b 2048 -f ~/.ssh/citadel

create
main.tf - change path to ssh key

terraform plan
