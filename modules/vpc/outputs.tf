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