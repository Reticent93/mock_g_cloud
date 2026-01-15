output "vpc_id" {
  description = "VPC ID"
  value = aws_vpc.first.id
}

output "vpc_cider" {
  description = "CIDR block of VPC"
  value = aws_vpc.first.id
}

output "public_subnet_ids" {
  description = "List of public subnet IDs"
  value = [for s in aws_subnet.primary_subnet : s.id if s.tags.Type == "public"]
}

output "private_subnet_ids" {
  description = "List of private subnet IDs"
  value = [for s in aws_subnet.primary_subnet : s.id if s.tags.Type == "private"]
}

output "db_subnet_ids" {
  description = "List of db subnet IDs"
  value = [for s in aws_subnet.primary_subnet : s.id if s.tags.Type == "db"]
}

output "alb_sg_id" {
  description = "SG ID for LB"
  value = aws_security_group.alb_sg.id
}

output "app_sg_id" {
  description = "SG ID for APP"
  value = aws_security_group.apps_sg.id
}

output "db_sg_id" {
  description = "SG ID for DB"
  value = aws_security_group.db_sg.id
}

output "flow_log_group_arn" {
  description = "ARN of the CloudWatch Log Group for Flow Logs"
  value = aws_flow_log.main.arn
}