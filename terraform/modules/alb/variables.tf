variable "project_name" {
  description = "Name of the project"
  type        = string
}

variable "environment" {
  description = "Environment (dev, prod, etc.)"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "security_group_id" {
  description = "ID of the security group for the ALB"
  type        = string
}

variable "subnet_ids" {
  description = "IDs of the subnets for the ALB"
  type        = list(string)
}