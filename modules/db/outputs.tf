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