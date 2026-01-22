data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_vpc" "first" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.project_name}-vpc"

  }
}


#---------------SECURITY GROUP----------------#
resource "aws_default_security_group" "default" {
  vpc_id = aws_vpc.first.id
}

resource "aws_security_group" "alb_sg" {
  # checkov:skip=CKV2_AWS_5:Attached to ALB in App module
  name = "${var.project_name}-alb-sg"
  description = "Inbound subnet traffic only"
  vpc_id = aws_vpc.first.id

  tags = {
      Name = "${var.project_name}-alb-sg"
  }
}



# Allow HTTPS from world ONLY to the LB
resource "aws_security_group_rule" "alb_https_ingress" {
  description = "Allows HTTPS traffic to LB"
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

# Allow HTTP from internet
resource "aws_security_group_rule" "alb_http_ingress" {
  # checkov:skip=CKV_AWS_260: Using port 80 for public access in this project
  description = "Allows HTTP traffic from internet"
  type              = "ingress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.alb_sg.id
}

# Allow LB to talk to Apps
resource "aws_security_group_rule" "alb_to_apps_egress" {
  description = "Allows LB to send traffic to Apps"
  type              = "egress"
  from_port         = 80
  to_port           = 80
  protocol          = "tcp"
  security_group_id = aws_security_group.alb_sg.id
  source_security_group_id = var.apps_sg.id
}

#---------------SUBNET-----------------------#
resource "aws_subnet" "primary_subnet" {
  for_each = tomap({ for subnet in local.subnet_config : subnet.name_suffix => subnet })
  vpc_id = aws_vpc.first.id
  cidr_block = cidrsubnet(aws_vpc.first.cidr_block, 4, each.value.netnum_offset )
  availability_zone = each.value.az_name

  tags = {
    Name = "${var.project_name}-${each.value.name_suffix}"
    Type = each.value.type
  }
}

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.first.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

resource "aws_nat_gateway" "main" {
  subnet_id = aws_subnet.primary_subnet["public_1"].id
  allocation_id = aws_eip.nat.id
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }
}


#---------------ROUTE TABLE-----------------------#
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.first.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-public-rt"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.first.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-private-rt"
  }
}

resource "aws_route_table_association" "public" {
  for_each = {
    for j, subnet in aws_subnet.primary_subnet : j => subnet
          if subnet.tags.Type == "public"
  }
  subnet_id = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = {
    for j, subnet in aws_subnet.primary_subnet : j => subnet
          if contains(["private", "db"], subnet.tags.Type)
  }
  subnet_id = each.value.id
  route_table_id = aws_route_table.private.id
}

resource "aws_flow_log" "main" {
  iam_role_arn = var.flow_log_role_arn
  log_destination = aws_cloudwatch_log_group.vpc_flow_log.arn
  traffic_type         = "ALL"
  vpc_id               = aws_vpc.first.id
}


#---------------KMS-----------------------#
resource "aws_cloudwatch_log_group" "vpc_flow_log" {
  name = "${var.project_name}-flow-logs"
  retention_in_days = var.flow_log_retention
  kms_key_id = aws_kms_key.flow_log_key.arn
}

resource "aws_kms_key" "flow_log_key" {
  description = "KMS keys for Flow Logs"
  deletion_window_in_days = var.key_deletion_window
  enable_key_rotation     = true
  policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        Sid : "Enable IAM User Permissions",
        "Effect" : "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "kms:*",
        Resource = "*"
      },
      {
        Sid = "Allow CloudWatch logs"
        Effect = "Allow"
        Principal = {
          Service = "logs.${data.aws_region.current.name}.amazonaws.com"
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:ReEncrypt*",
          "kms:GenerateDataKey*",
          "kms:DescribeKey"
        ]
        Resource = "*"
        Condition = {
          ArnLike = {
            "kms:EncryptionContext:aws:logs:arn" : "arn:aws:logs:${data.aws_region.current.name}:${data.aws_caller_identity.current.account_id}:log-group:${var.project_name}-flow-logs"
          }
        }
      }
    ]
  })

}


