resource "aws_security_group" "load-balancer" {
  name        = "${var.env_code}-load-balancer" #using env var from variables.tf
  description = "Allow port 80 TCP inbound for ELB"
  vpc_id      = var.vpc_id #using variables from module config

  ingress {
    description = "http to ELB"
    from_port   = 80 #443
    to_port     = 80 #443
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Everywhere"
    from_port   = 0
    to_port     = 65535
    protocol    = "TCP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.env_code}-load-balancer" #using env var from variables.tf
  }
}

resource "aws_lb" "main" {
  name               = "${var.env_code}-load-balancer"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.load-balancer.id] #using sg created in the same file
  subnets            = var.public_subnet_id               #using variables from module config

  tags = {
    Name = "${var.env_code}-load-balancer" #using env var from variables.tf
  }
}

resource "aws_lb_target_group" "main" {
  name     = "${var.env_code}-target-group"
  port     = 80 #on instances
  protocol = "HTTP" 
  vpc_id   = var.vpc_id #using variables from module config

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic-port"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
  }
}

#commented as we added auto scaling
/* resource "aws_lb_target_group_attachment" "main" {
  count = 2

  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.private[count.index].id #forward request to private instance
  port             = 80
} */

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80 #443
  protocol          = "HTTP" #"HTTPS"
  certificate_arn   = aws_acm_certificate.main.arn #as a part of ACM implementation
  ssl_policy        = "ELBSecurityPolicy-2016-00" #as a part of ACM implementation

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}

#DNS part
data "aws_route53_zone" "main" {
  name = "dns_name_here.net"
}

resource "aws_route53_record" "www" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "www.${data.aws_route53_zone.main.name}"
  type    = "CNAME"
  ttl     = "300"
  records = [aws_lb.main.dns_name]
}

#ACM - Amazon Certificate Manager to gain SSL cert
resource "aws_acm_certificate" "main" {
  domain_name = "www.${data.aws_route53_zone.main.name}"
  validation_method = "DNS"

  tags = {
    Name = var.env_code 
  }
}

resource "aws_route53_record" "main" {
  for_each = {
    for dvo in aws_acm_certificate.main.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    } 
  }
  
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.main.zone_id
}

resource "aws_acm_certificate_validation" "main" {
  certificate_arn         = aws_acm_certificate.main.arn
  validation_record_fqdns = [for record in aws_route53_record.main : record.fqdn]
}