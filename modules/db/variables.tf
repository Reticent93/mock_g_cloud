variable "project_name" {
  description = "Name of project"
  type = string
}

variable "vpc_id" {
  description = "ID of VPC"
  type = string
}

variable "apps_sg_id" {
  description = "ID of App SG"
  type = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs"
  type = list(string)
}

variable "instance_class" {
  description = "The type of DB instance"
  type = string
  default = "db.t3.micro"
}