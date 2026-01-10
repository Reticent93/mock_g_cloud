data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_vpc" "first" {
  cidr_block = var.vpc_cidr

  tags = {
    Name = "${var.project_name}-vpc"

  }
}

resource "aws_security_group" "alb_sg" {
  name = "${var.project_name}-alb-sg"
  description = "Inbound subnet traffic only"
  vpc_id = aws_vpc.first.id

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
    description = "Outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
      Name = "${var.project_name}-alb-sg"
  }
}

resource "aws_security_group" "apps_sg" {
  name = "${var.project_name}-apps-sg"
  vpc_id = aws_vpc.first.id

  ingress {
    description = "ALB traffic"
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
  description = "Allows ALB SG traffic only"
  vpc_id = aws_vpc.first.id

  ingress {
    description = "Database access from app server"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    security_groups = [aws_security_group.apps_sg.id]
  }

  egress {
    description = "Allow outbound for patches/monitoring only"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [aws_vpc.first.cidr_block]
  }

  tags = {
    Name = "${var.project_name}-db-sg"
  }
}

resource "aws_subnet" "primary_subnet" {
  for_each = { for config in local.subnet_config : config.name_suffix => config }
  vpc_id = aws_vpc.first.id
  cidr_block = cidrsubnet(aws_vpc.first.cidr_block, 4 , each.value.netnum_offset )
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