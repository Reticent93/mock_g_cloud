terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.81.0"
    }
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

# Outbound traffic to internet
resource "aws_security_group_rule" "db_all_egress" {
  description = "Allow outbound traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = -1
  security_group_id = aws_security_group.db_sg.id
}

# Allows DB SG to receive traffic from App SG
resource "aws_security_group_rule" "db_from_apps_ingress" {
  description = "Allows traffic from app to db"
  type = "ingress"
  from_port         = 5432
  to_port           = 5432
  protocol    = "tcp"
  security_group_id = aws_security_group.db_sg.id
  source_security_group_id = var.apps_sg_id
}


#-----------------SUBNET-------------------#

resource "aws_db_subnet_group" "db_subnet_group" {
    name = "${var.project_name}-db-sg"
  subnet_ids = var.private_subnet_ids

  tags = {
    Name = "${var.project_name}-db-subnet-group"
  }
}

resource "aws_db_instance" "first_postgres" {
  identifier = "${project_name}-db"
  instance_class = var.instance_class
  engine = "postgres"
  engine_version = "10.9.4"
  allocated_storage = 20
  db_name = "myfirstpostgres"
  username = "dbadmin"

  manage_master_user_password = true
  db_subnet_group_name = aws_db_subnet_group.db_subnet_group.id
  vpc_security_group_ids = [aws_security_group.db_sg.id]
  skip_final_snapshot = true
  publicly_accessible = false

}