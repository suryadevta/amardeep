resource "aws_lb" "test-lb" {
  name               = "gravystack-Prod-lb"
  load_balancer_type = "application"
  internal           = false
  subnets            = module.vpc.public_subnets
  tags = {
    "env"       = "Prod"
    "createdBy" = "Robinder"
  }
  security_groups = [aws_security_group.lb.id]
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_security_group" "lb" {
  name   = "gravystack-Prod-lb-sg"
  vpc_id = module.vpc.vpc_id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  tags = {
    "env"       = "Prod"
    "createdBy" = "Robinder"
  }
  lifecycle {
    prevent_destroy = true
  }
}


resource "aws_lb_target_group" "lb_target_group" {
  name        = "gravystack-Prod-target-group"
  port        = "80"
  protocol    = "HTTP"
  target_type = "instance"
  vpc_id      = module.vpc.vpc_id
  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 2
    timeout             = 60
    interval            = 80
    matcher             = "200"
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_lb_listener" "web-listener" {
  load_balancer_arn = aws_lb.test-lb.arn
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "ELBSecurityPolicy-2016-08"
  certificate_arn   = "arn:aws:acm:us-east-1:710866754724:certificate/36dd696a-76bc-4ba3-a406-7c1ad646c062"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.lb_target_group.arn
  }
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_lb_listener" "web-listener_http" {
  load_balancer_arn = aws_lb.test-lb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type = "redirect"

    redirect {
      port        = "443"
      protocol    = "HTTPS"
      status_code = "HTTP_301"
    }
  }
  lifecycle {
    prevent_destroy = true
  }

}