terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
  }
}
resource "aws_vpc" "primary" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.project_name}-vpc"

  }
}

resource "aws_subnet" "private" {
  vpc_id = aws_vpc.primary.id
  cidr_block = cidrsubnets(aws_vpc.primary.cidr_block, 3)
  availability_zone = var.availability_zones[count.index]
  map_public_ip_on_launch = false

  tags = {
    Name = "App-Private-Subnet-${var.availability_zones[count.index]}"
  }
}

resource "aws_security_group" "alb_sg" {
  name = "${var.project_name}-alb-sg"
  description = "Allow inbound traffic from public subnet only"
  vpc_id = aws_vpc.primary.id

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Traffic to App Servers"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.alb_sg.id]
  }

  tags = {
      Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_security_group" "app_sg" {
  name = "${var.project_name}-app-sg"
  vpc_id = aws_vpc.primary.id

  ingress {
    description = "Traffic from ALB group only"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-app-sg"
  }
}

resource "aws_security_group" "db_sg" {
  description = "Allows traffic only from ALB security group"
  vpc_id = aws_vpc.primary.id

  ingress {
    description = "Database access from app server"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }

  egress {
    description = "Allow outbound only for patches/monitoring"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

resource "aws_subnet" "all_subnets" {
  vpc_id = aws_vpc.primary.id
  cidr_block = cidrsubnet(aws_vpc.primary.cidr_block, 4, 2)

}

resource "aws_subnet" "public" {
  vpc_id = aws_vpc.primary.id
}