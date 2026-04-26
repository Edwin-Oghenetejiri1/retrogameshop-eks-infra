output "cluster_name" {
  value       = aws_eks_cluster.cluster.name
  description = "EKS cluster name"
}

output "cluster_endpoint" {
  value       = aws_eks_cluster.cluster.endpoint
  description = "EKS cluster endpoint"
}

output "cluster_version" {
  value       = aws_eks_cluster.cluster.version
  description = "EKS cluster Kubernetes version"
}

output "cluster_ca_certificate" {
  value       = aws_eks_cluster.cluster.certificate_authority[0].data
  description = "EKS cluster CA certificate"
}

output "oidc_provider_arn" {
  value       = aws_iam_openid_connect_provider.this.arn
  description = "OIDC provider ARN for IRSA"
}

output "oidc_provider_url" {
  value       = aws_iam_openid_connect_provider.this.url
  description = "OIDC provider URL"
}