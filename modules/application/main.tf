data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["al2023-ami-*-x86_64"]
  }
}

resource "aws_security_group" "apps_sg" {
  # checkov:skip=CKV2_AWS_5:Attached to EC2 in App module
  name = "${var.project_name}-apps-sg"
  description = "Security group for apps"
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

# Inbound traffic ONLY from LB
resource "aws_vpc_security_group_ingress_rule" "apps_from_alb_ingress" {
  # checkov:skip=CKV_AWS_260: Port 80 is restricted to ALB SG, not public
  description = "Allow traffic ONLY from ALB"
  from_port         = 80
  to_port           = 80
  ip_protocol          = "tcp"
  security_group_id = aws_security_group.apps_sg.id
  referenced_security_group_id = var.alb_sg_id
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
    timeout = 5
    interval = 30
    matcher = "200"
  }
}

resource "aws_vpc_security_group_ingress_rule" "db_from_apps_ingress" {
  description = "Allow access from App instances on PG port"
  from_port = 5432
  to_port = 5432
  ip_protocol       = "tcp"
  security_group_id = var.db_security_group_id
  referenced_security_group_id = aws_security_group.apps_sg.id

  tags = {
    Name = "${var.project_name}-db-from-app"
  }
}

resource "aws_vpc_security_group_egress_rule" "apps_to_db_egress" {
  description = "Allow access from App to reach DB"
  from_port = 5432
  to_port = 5432
  ip_protocol       = "tcp"
  security_group_id = aws_security_group.apps_sg.id
  referenced_security_group_id = var.db_security_group_id

  tags = {
    Name = "${var.project_name}-app-to-db"
  }
}

resource "aws_vpc_security_group_egress_rule" "apps_to_web_egress" {
  description = "Allows access to web for updates"
  from_port         = 443
  to_port           = 443
  ip_protocol       = "tcp"
  cidr_ipv4 = "0.0.0.0/0"
  security_group_id = aws_security_group.apps_sg.id
}

resource "aws_vpc_security_group_egress_rule" "apps_to_any_egress" {
  #checkov:skip=CKV_AWS_141: Need full access for dnf updates. Will update later
  description = "Allow outbound access to the app"
  ip_protocol       = "-1"
  cidr_ipv4 = "0.0.0.0/0"
  security_group_id = aws_security_group.apps_sg.id
}

resource "aws_launch_template" "app_lt" {
  name_prefix = "${var.project_name}-lt"
  image_id = var.ami_id != "" ? var.ami_id : data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  update_default_version = true

  iam_instance_profile {
    name = var.aws_iam_instance_profile_name
  }

  network_interfaces {
    associate_public_ip_address = false
    security_groups = [aws_security_group.apps_sg.id]
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
    http_put_response_hop_limit = 1 # This is the default
  }

  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    project_name = var.project_name
    aws_region = var.aws_region
    db_secret_arn = var.db_secret_arn
    db_endpoint = var.db_endpoint
  }))
}

resource "aws_autoscaling_group" "app_asg" {
  vpc_zone_identifier = var.private_subnet_ids
  target_group_arns = [aws_alb_target_group.app_tg.arn]
  health_check_type = "ELB"
  health_check_grace_period = 300
  wait_for_capacity_timeout = "10m"
  desired_capacity = 2
  min_size = 1
  max_size = 3
  launch_template {
    id      = aws_launch_template.app_lt.id
    version = aws_launch_template.app_lt.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = 50
    }
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