output "iam_instance_profile" {
  value = module.base.aws_instance_profile_name
}

output "github_deploy_role_arn" {
  value = var.create_deploy_role ? module.base.github_deploy_role_arn : null
}