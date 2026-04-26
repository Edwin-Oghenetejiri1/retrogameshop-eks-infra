variable "region" {
  type        = string
  description = "AWS region"
}

variable "env" {
  type        = string
  description = "Environment name"
}

variable "vpc_name" {
  type        = string
  description = "Name of the VPC"
}

variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "eks_version" {
  type        = string
  description = "Kubernetes version"
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
  description = "Private subnet CIDR blocks"
}

variable "public_subnets_cidr" {
  type        = list(string)
  description = "Public subnet CIDR blocks"
}

variable "admin_arn" {
  type        = string
  description = "ARN of the admin IAM user"
}

variable "principal_arn" {
  type        = string
  description = "ARN of the CI/CD pipeline IAM user"
}

variable "principal_arn_name" {
  type        = string
  description = "Name of the CI/CD principal"
  default     = "pipeline"
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
  description = "Node groups configuration"
}

variable "repo_url" {
  type        = string
  description = "URL of your k8s manifests GitHub repo"
}