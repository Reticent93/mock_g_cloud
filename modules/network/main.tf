data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_vpc" "first" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

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

resource "aws_vpc_security_group_ingress_rule" "alb_http" {
  # checkov:skip=CKV_AWS_260: This is a public ALB, must be open to the internet
  description = "Allow HTTP from outside only from LB"
  from_port = 80
  to_port = 80
  ip_protocol       = "tcp"
  cidr_ipv4 = "0.0.0.0/0"
  security_group_id = aws_security_group.alb_sg.id
}

resource "aws_vpc_security_group_ingress_rule" "alb_https" {
  description = "Allow HTTPS from outside only from LB"
  from_port = 443
  to_port = 443
  ip_protocol       = "tcp"
  cidr_ipv4 = "0.0.0.0/0"
  security_group_id = aws_security_group.alb_sg.id
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
  subnet_id = aws_subnet.primary_subnet["public-1"].id
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
    nat_gateway_id = aws_nat_gateway.main.id
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
          Service = "logs.${data.aws_region.current.id}.amazonaws.com"
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
  tags = {
    Description = "Encryption for Flow Logs"
    Name = "${var.project_name}-flow-log-key"
  }
}


resource "aws_security_group" "db_sg" {
  # checkov:skip=CKV2_AWS_5:Attached to RDS in the database module
  description = "Allows ALB SG traffic only"
  vpc_id = var.vpc_id

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

# Allows DB SG to receive traffic from App SG
resource "aws_vpc_security_group_ingress_rule" "db_from_apps_ingress" {
  description = "Allows traffic from app to db"
  from_port         = 5432
  to_port           = 5432
  ip_protocol    = "tcp"
  security_group_id = aws_security_group.db_sg.id
  referenced_security_group_id = var.apps_sg_id
}


#-----------------SUBNET-------------------#
resource "aws_db_subnet_group" "db_subnet_group" {
  name = "${var.project_name}-db-subnet-sg"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}


#-----------------RDS INSTANCE-------------------#
resource "aws_db_parameter_group" "db_pg" {
  name = "${var.project_name}-db-pg"
  family = "postgres17"

  parameter {
    name  = "log_connections"
    value = "1"
  }

  parameter {
    name  = "log_min_duration_statement"
    value = "1000"
  }

  parameter {
    name = "rds.force_ssl"
    value = "1"
  }

}
resource "aws_db_instance" "first_postgres" {
  # checkov:skip=CKV_AWS_293:Deletion protection set to false for daily destroy
  # checkov:skip=CKV_AWS_354: Using AWS managed key is ok for dev
  identifier = "${var.project_name}-db"
  instance_class = var.instance_class
  engine = "postgres"
  engine_version = "17"
  allocated_storage = 20
  db_name = "myfirstpostgres"
  username = "dbadmin"
  multi_az = true
  monitoring_interval = 60
  performance_insights_enabled = true
  deletion_protection = false # Set to true for production
  auto_minor_version_upgrade = true
  manage_master_user_password = true
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot = true
  publicly_accessible = false
  iam_database_authentication_enabled = true
  storage_encrypted = true
  copy_tags_to_snapshot = true
  parameter_group_name = aws_db_parameter_group.db_pg.name
  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]
}

