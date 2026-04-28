variable "region" {
  type = string
}

variable "env" {
  type = string
}

variable "vpc_name" {
  type = string
}

variable "cluster_name" {
  type = string
}

variable "eks_version" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "azs" {
  type = list(string)
}

variable "private_subnets_cidr" {
  type = list(string)
}

variable "public_subnets_cidr" {
  type = list(string)
}

variable "admin_arn" {
  type = string
}

variable "principal_arn" {
  type = string
}

variable "principal_arn_name" {
  type    = string
  default = "pipeline"
}

variable "node_groups" {
  type = map(object({
    instance_types = list(string)
    capacity_type  = string
    scaling_config = object({
      desired_size = number
      max_size     = number
      min_size     = number
    })
  }))
}