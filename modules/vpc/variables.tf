variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "vpc_cidr" {
  type        = string
  description = "CIDR block for the VPC"
}

variable "azs" {
  type        = list(string)
  description = "Availability zones"
}

variable "private_subnets_cidr" {
  type        = list(string)
  description = "CIDR blocks for private subnets"
}

variable "public_subnets_cidr" {
  type        = list(string)
  description = "CIDR blocks for public subnets"
}