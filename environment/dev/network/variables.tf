variable "project_name" {
  type        = string
}

variable "flow_log_role_arn" {
  type        = string
  default     = null
}

variable "vpc_cidr" {
  type        = string
}

variable "state_bucket_name" {
  type        = string
}

variable "aws_region" {
  type        = string
}