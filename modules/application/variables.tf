variable "project_name" {
  description = "Name of project"
  type = string
}

variable "aws_region" {
  description = "AWS region to launch servers"
  type = string
}

variable "vpc_id" {
  description = "ID of VPC"
  type = string
}

variable "vpc_cidr" {
  description = "CIDR of VPC"
  type = string
}

variable "public_subnet_ids" {
  description = "IDs of Public Subnets"
  type = list(string)
}

variable "private_subnet_ids" {
  description = "IDs of Private Subnets"
  type = list(string)
}

variable "alb_sg_id" {
  description = "ID of ALB SG"
  type = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type = string
  default = "t3.micro"
}

variable "ami_id" {
  description = "ID of AMI to use for the instance"
  type = string
}

variable "db_sg_id" {
  description = "ID of DB SG"
  type = string
}

variable "aws_iam_instance_profile_name" {
  description = "IAM instance profile id"
  type = string
}

variable "db_endpoint" {
  description = "endpoint of the RDS"
  type = string
}

variable "db_secret_arn" {
  description = "ARN of the DB password secret in RDS"
  type = string
}


