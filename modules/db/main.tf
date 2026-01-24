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

}
resource "aws_db_instance" "first_postgres" {
  # checkov:skip=CKV_AWS_293:Deletion protection set to false for daily destroy
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

