output "deploy_role_arn" {
  description = "The ARN of the GitHub Deployment Role"
  value       = module.dev_iam.deploy_role_arn
}
