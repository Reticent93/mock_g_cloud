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

variable "vpc_id" {
  description = "Id of the VPC"
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
  default     = "GitHub_Actions_Deploy_Role_DEV"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "aws_cloudwatch_log_group" {
  description = "CloudWatch log group that will receive log objects"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  type        = string
}

variable "flow_log_retention" {
  description = "Number of days to keep cloudwatch flow logs"
  type        = string
  default     = "7"
}

variable "name_suffix" {
  description = "Suffix for the resources"
  type        = string
}

variable "db_resource_id" {
  description = "resource id for db instance"
  type        = string
}

variable "db_sg_id" {
  description = "ID of DB SG"
  type = string
}

variable "app_sg_id" {
  description = "ID of App SG"
  type = string
}

variable "alb_sg_id" {
  description = "ID of ALB SG"
  type = string
}

variable "aws_iam_instance_profile_name" {
  description = "IAM instance profile for App"
  type        = string
}