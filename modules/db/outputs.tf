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

# output "db_subnet_ids" {
#   description = "List of db subnet IDs"
#   value = [for s in aws_subnet.primary_subnet : s.id if s.tags.Type == "db"]
# }

output "db_endpoint" {
  description = "endpoint for RDS instance"
  value = split(":", aws_db_instance.first_postgres.endpoint)[0]
}