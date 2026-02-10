output "deploy_role_arn" {
  description = "The ARN of the GitHub Deployment Role"
  value = element(concat(aws_iam_role.github_deploy_role.*.arn, [""]), 0)
}

output "flow_log_role_arn" {
  description = "The ARN of the IAM role for VPC Flow Logs"
  value = aws_iam_role.vpc_flow_log_role.arn
}

output "aws_instance_profile_name" {
  description = "IAM instance profile name"
  value = aws_iam_instance_profile.app_profile.name
}

output "github_deploy_role_arn" {
  value = aws_iam_role.github_deploy_role[0].arn
}