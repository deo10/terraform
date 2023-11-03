#.tflint.hcl
plugin "terraform" {
  enabled = true
  #preset  = "recommended"
}

#https://github.com/terraform-linters/tflint-ruleset-aws

plugin "aws" {
    enabled = true
    version = "0.27.0"
    source  = "github.com/terraform-linters/tflint-ruleset-aws"
}