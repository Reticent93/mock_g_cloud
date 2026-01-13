variable "oidc_provider_arn" {
  description = "ARN for the IAM OIDC role"
  type        = string
}

variable "repo_owner" {
  description = "Owner of the repository."
  type        = string
}

variable "repo_name" {
  description = "Name of the repository."
  type        = string
}

variable "state_bucket_name" {
  description = "Name of S3 bucket to store Terraform state files"
  type        = string
}

variable "create_deploy_role" {
  description = "Controls whether an IAM role should be created"
  type        = bool
  default     = false
}

variable "deploy_role_name" {
  description = "Name of the IAM role GitHub deployment will assume"
  type        = string
  default = "GitHub_Actions_Deploy_Role_DEV"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

