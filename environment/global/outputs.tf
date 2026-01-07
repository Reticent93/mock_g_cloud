output "oidc_provider_arn" {
  description = "The ARN of the GitHub OIDC provider for IAM role trust policies."
  value       = module.global_iam.oidc_provider_arn
}