variable "cluster_name" {
  type        = string
  description = "Name of the EKS cluster"
}

variable "eks_version" {
  type        = string
  description = "Kubernetes version for the EKS cluster"
}

variable "subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs for the EKS cluster"
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
  description = "Map of node groups with their configurations"
  default     = {}
}

variable "admin_arn" {
  type        = string
  description = "ARN of the admin user to administer the EKS cluster"
}

variable "principal_arn" {
  type        = string
  description = "ARN of the principal used by the pipeline to access the cluster"
}

variable "principal_arn_name" {
  type        = string
  description = "Name of the principal ARN"
  default     = "admin"
}