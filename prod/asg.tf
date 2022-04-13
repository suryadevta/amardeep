
data "aws_ami" "amazon_linux" {
  most_recent = true

  filter {
    name   = "name"
    values = ["amzn-ami*amazon-ecs-optimized"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon", "self"]
}

resource "aws_security_group" "ec2-sg" {
  #depends_on = [module.vpc]
  name        = "gravystack-Prod-sg"
  description = "gravystack-Prod-sg"
  vpc_id      = module.vpc.vpc_id 

  ingress {
    from_port = 0
    to_port   = 65535
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "gravystack-Prod-sg"
  }
  lifecycle {
    prevent_destroy = true
  }  
}

resource "aws_launch_configuration" "lc" {
  name          = "gravystack-Prod-lc-1"
  image_id      = "ami-0706a79e169de19a2"
  instance_type = "t3.micro"
  iam_instance_profile        = aws_iam_instance_profile.ecs_service_role.name
  key_name                    = var.key_name
  security_groups             = [aws_security_group.ec2-sg.id]
  associate_public_ip_address = false
  user_data                   = <<EOF
#! /bin/bash
sudo apt-get update
sudo echo "ECS_CLUSTER=gravystack-stag" >> /etc/ecs/ecs.config
EOF
lifecycle {
    prevent_destroy = true
  }
}

resource "aws_autoscaling_group" "asg" {
  name                 = "gravystack-Prod-asg"
  launch_configuration = aws_launch_configuration.lc.name
  min_size             = 2
  max_size             = 6
  desired_capacity     = 2
  #health_check_type         = "ELB"
  #health_check_grace_period = 300
  vpc_zone_identifier = module.vpc.private_subnets
  target_group_arns   = [aws_lb_target_group.lb_target_group.arn]

  #  protect_from_scale_in = false
  tag {
    key                 = "Name"
    value               = "gravystack-Prod"
    propagate_at_launch = true
  }
  lifecycle {
    prevent_destroy = true
  }
}
