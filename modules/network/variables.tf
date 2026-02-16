variable "project_name" {
  description = "Name of the project"
  type = string
}

variable "vpc_cidr" {
  description = "CIDR for the VPC"
  type = string
}

variable "flow_log_retention" {
  type        = number
  description = "Days to keep logs"
}

variable "flow_log_role_arn" {
  description = "IAM role for flow logs"
  type        = string
  default     = null
}

variable "key_deletion_window" {
  description = "Automatically delete object with days"
  type        = number
}

variable "instance_class" {
  description = "The type of DB instance"
  type = string
  default = "db.t3.micro"
}

variable "multi_az" {
  type = bool
  default = false
}

variable "rds_monitoring_arn" {
  description = "ARN for RDS enhanced monitoring "
  type = string
}
