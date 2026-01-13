output "oidc_provider_arn" {
  description = "The ARN of the created IAM Role associated with the Github Action"
  value = var.create_oidc_provider ? aws_iam_openid_connect_provider.github_actions[0].arn : null
}

output "deploy_role_arn" {
  description = "The ARN of the GitHub Deployment Role"
  value = element(concat(aws_iam_role.github_deploy_role.*.arn, [""]), 0)
}

output "flow_log_role_arn" {
  description = "The ARN of the IAM role for VPC Flow Logs"
  value = aws_iam_role.vpc_flow_log_role.arn
}