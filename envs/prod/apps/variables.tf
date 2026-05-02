variable "region" {
  type = string
}

variable "env" {
  type = string
}

variable "repo_url" {
  type = string
}

variable "grafana_password" {
  type        = string
  description = "Grafana admin password"
  default     = "admin123"
  sensitive   = true
}