data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_alb_target_group" "app_tg" {
  # checkov:skip=CKV_AWS_378:Target group is using HTTP for this project. No SSL certificate is available
  name = "${var.project_name}-tg"
  port = 80
  protocol = "HTTP"
  vpc_id = var.vpc_id

  health_check {
    path = "/"
    healthy_threshold   = 2
    unhealthy_threshold = 6
  }
}

resource "aws_launch_template" "app_lt" {
  name_prefix = "${var.project_name}-lt"
  image_id = data.ami_id != "" ? data.ami_id : data.aws_ami.amazon_linux.id
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups = [var.apps_sg_id]
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 1 # This is the default
  }
  user_data = base64encode(<<-EOF
              #!/bin/bash
              yum update -y
              yum install -y httpd
              systemctl start httpd
              systemctl enable httpd
              echo "<h1>Hello from ${var.project_name}</h1>" > /var/www/html/index.html
              EOF
  )
}

resource "aws_autoscaling_group" "app_asg" {
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns = [aws_alb_target_group.app_tg.arn]
  desired_capacity = 2
  min_size = 1
  max_size = 3
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = "$Latest"
  }

  tag {
    key = "${var.project_name}-app-sg"
    propagate_at_launch = true
    value = "development"
  }
}

resource "aws_alb" "main" {
  # checkov:skip=CKV_AWS_91:Access logging is not required for this; temporary project
  # checkov:skip=CKV_AWS_150: Deletion protection is disabled; wanting to use terraform destroy dail
  # checkov:skip=CKV2_AWS_28: WAF is too expensive for this project
  # checkov:skip=CKV2_AWS_5: Attached to ALB via the listener and target group
  # checkov:skip=CKV2_AWS_20: Port 80 is used for this project; redirect would require a certificate
  name = "${var.project_name}-alb"
  load_balancer_type = "application"
  security_groups = [var.alb_sg_id]
  subnets = var.public_subnet_ids
  drop_invalid_header_fields = true
}

resource "aws_alb_listener" "http" {
  # checkov:skip=CKV_AWS_2:Port 80 is used for this project; redirect would require a certificate
  # checkov:skip=CKV_AWS_103: TLS 1.2+ not applicable for HTTP port 80
  load_balancer_arn = aws_alb.main.id
  port = 80
  protocol = "HTTP"

  default_action {
    type = "forward"
    target_group_arn = aws_alb_target_group.app_tg.arn
  }

  # Correct way
  # default_action {
  #   type = "redirect"
  #   redirect {
  #     port = "443"
  #     protocol = "HTTPS"
  #     status_code = "HTTP_301"
  #   }
  # }
}