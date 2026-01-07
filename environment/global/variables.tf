variable "oidc_provider_arn" {
  description = "ARN of the OIDC provider"
  type        = string
}

variable "repo_owner" {
  description = "Owner of the repository."
  type        = string
}

variable "repo_name" {
  description = "The name of the repository."
  type        = string
}

variable "state_bucket_name" {
  description = "Name of S3 bucket to store Terraform state files"
  type        = string
}

variable "lock_table_name" {
  description = "Name for dynamodb table to hold lock"
  type        = string
}
variable "deploy_role_name" {
  description = "Name of the IAM role GitHub deployment will assume"
  type        = string
  default = "GitHub_Actions_Deploy_Role_DEV"
}
