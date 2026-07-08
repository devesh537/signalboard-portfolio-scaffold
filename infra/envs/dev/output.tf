output "cluster_name" {
  description = "EKS Cluster Name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS API Server Endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_certificate_authority_data" {
  description = "Cluster CA Certificate"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

output "aws_region" {
  description = "AWS Region"
  value       = var.aws_region
}
