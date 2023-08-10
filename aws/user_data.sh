#!/bin/bash

sudo yum update -y
sudo yum install -y httpd git
git clone https://github.com/gabrielecirulli/2048.git
cp -R 2048/* /var/www/html
sudo systemctl start httpd && sudo systemctl enable httpd
