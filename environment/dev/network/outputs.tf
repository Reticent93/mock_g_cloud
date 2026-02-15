output "vpc_id" {
  description = "VPC ID"
  value = module.network.vpc_id
}

output "vpc_cidr" {
  description = "CIDR block of VPC"
  value = module.network.vpc_cidr
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value = module.network.public_subnet_ids
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value = module.network.private_subnet_ids
}

output "alb_sg_id" {
  description = "SG ID for LB"
  value = module.network.alb_sg_id
}

output "flow_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for Flow Logs"
  value = module.network.flow_log_group_arn
}

output "rds_hostname" {
  description = "RDS instance hostname"
  value = module.network.rds_hostname
}

output "rds_port" {
  description = "RDS instance port"
  value = module.network.rds_port
}

output "rds_username" {
  description = "RDS instance username"
  value = module.network.rds_username
}

output "db_resource_id" {
  value = module.network.db_resource_id
}

output "db_endpoint" {
  description = "endpoint for RDS instance"
  value = split(":", module.network.db_endpoint)[0]
}

output "db_password_secret_arn" {
  value = module.network.db_password_secret_arn
}

output "db_security_group_id" {
  description = "DB SG ID for App layer"
  value = module.network.db_security_group_id
}

output "alb_security_group_id" {
  description = "ALB SG ID for App layer"
  value = module.network.alb_security_group_id
}