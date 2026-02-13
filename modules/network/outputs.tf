output "vpc_id" {
  description = "VPC ID"
  value = aws_vpc.first.id
}

output "vpc_cidr" {
  description = "CIDR block of VPC"
  value = aws_vpc.first.cidr_block
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value = [for s in aws_subnet.primary_subnet : s.id if s.tags.Type == "public"]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value = [for s in aws_subnet.primary_subnet : s.id if s.tags.Type == "private"]
}

output "alb_sg_id" {
  description = "SG ID for LB"
  value = aws_security_group.alb_sg.id
}

output "flow_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for Flow Logs"
  value = aws_flow_log.main.arn
}

output "rds_hostname" {
  description = "RDS instance hostname"
  value = aws_db_instance.first_postgres.address
}

output "rds_port" {
  description = "RDS instance port"
  value = aws_db_instance.first_postgres.port
}

output "rds_username" {
  description = "RDS instance username"
  value = aws_db_instance.first_postgres.username
}

output "db_resource_id" {
  value = aws_db_instance.first_postgres.resource_id
}

output "db_endpoint" {
  description = "endpoint for RDS instance"
  value = split(":", aws_db_instance.first_postgres.endpoint)[0]
}

output "db_password_secret_arn" {
  value = aws_db_instance.first_postgres.master_user_secret[0].secret_arn
}

output "db_security_group_id" {
  description = "DB SG ID for App layer"
  value = aws_security_group.db_sg.id
}

output "alb_security_group_id" {
  description = "ALB SG ID for App layer"
  value = aws_security_group.alb_sg.id
}