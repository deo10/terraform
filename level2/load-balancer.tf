resource "aws_security_group" "load-balancer" {
  name        = "${var.env_code}-load-balancer" #using env var from variables.tf
  description = "Allow port 80 TCP inbound for ELB"
  vpc_id      = data.terraform_remote_state.level1.ouputs.vpc_id #using outputs from level1

  ingress {
    description = "http to ELB"
    from_port   = 80
    to_port     = 80
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
  security_groups    = [aws_security_group.load-balancer]                          #using sg created in the same file
  subnets            = data.terraform_remote_state.level1.outputs.public_subnet_id #using outputs from level1

  tags = {
    Name = "${var.env_code}-load-balancer" #using env var from variables.tf
  }
}

resource "aws_lb_target_group" "main" {
  name     = "${var.env_code}-target-group"
  port     = 80
  protocol = "HTTP"
  vpc_id   = data.terraform_remote_state.level1.ouputs.vpc_id #using outputs from level1

  health_check {
    enabled             = true
    path                = "/"
    port                = "traffic port"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
  }
}

resource "aws_lb_target_group_attachment" "main" {
  count = 2

  target_group_arn = aws_lb_target_group.main.arn
  target_id        = aws_instance.private[count.index].id #forward request to private instance
  port             = 80
}

resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.main.arn
  }
}