#find values for envs in terraform.tfvars file
variable "env_code" {
  default = "boston" #should be no more than 6 symbols
}