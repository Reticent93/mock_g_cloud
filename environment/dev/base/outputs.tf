output "iam_instance_profile" {
  value = module.base.aws_instance_profile_name
}

output "db_password_secret_arn" {
  value = module.base.db_password_secret_arn
}

output "github_deploy_role_arn" {
  value = var.create_deploy_role ? module.base.github_deploy_role_arn : null
}