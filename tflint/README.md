#install tflint
curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash

#create .tflint.hcl file in repo folder

#init plug-ins that are configured in .tflint.hcl file
tflint --init

#check
tflint


#GIT pre-commit hook configuration#

pip install pre-commit

#or brew
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install pre-commit

#optional
git init

create a file named .pre-commit-config.yaml

cat <<EOF > .pre-commit-config.yaml
repos:
- repo: https://github.com/antonbabenko/pre-commit-terraform
  rev: <ADD_VERSION> # Get the latest from: https://github.com/antonbabenko/pre-commit-terraform/releases
  hooks:
    - id: terraform_tflint
EOF

#install pre-commit functionality
pre-commit install

#test against all files
pre-commit run -a

#test against specific files
pre-commit run --files main.tf