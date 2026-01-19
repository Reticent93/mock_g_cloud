output "deploy_role_arn" {
  description = "The ARN of the GitHub Deployment Role"
  value       = module.dev_iam.deploy_role_arn
}

output "the_website_url" {
  value = "http://${module.dev_apps.alb_dns_name}"
}
