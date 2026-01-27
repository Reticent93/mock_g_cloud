output "alb_dns_name" {
  description = "DNS name for ALB"
  value = aws_alb.main.dns_name
}

output "alb_zone_id" {
  description = "Zone ID of ALB"
  value = aws_alb.main.zone_id
}

output "asg_name" {
  description = "Name of ASG"
  value = aws_autoscaling_group.app_asg.name
}

output "app_sg_id" {
  value = aws_security_group.apps_sg.id
}

output "ami_id" {
  value = aws_launch_template.app_lt.image_id
}