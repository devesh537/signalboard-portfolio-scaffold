module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.31"

  cluster_name    = "${var.project_name}-${var.environment}"
  cluster_version = var.cluster_version

  # Auto Mode — AWS manages node provisioning, kube-proxy, CoreDNS, EBS CSI.
  # Tradeoff documented in README: less node-level control, but far less
  # operational overhead for an intermittently-run project. See README
  # "Design decisions" section.
  cluster_compute_config = {
    enabled    = true
    node_pools = var.node_pools
  }

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true
  authentication_mode             = "API"

  cluster_encryption_config = {
    resources = ["secrets"]
  }

  cluster_enabled_log_types = [
    "api", "audit", "authenticator", "controllerManager", "scheduler"
  ]

  enable_cluster_creator_admin_permissions = true

  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

output "cluster_name" {
  value = module.eks.cluster_name
}
output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}
output "cluster_certificate_authority_data" {
  value = module.eks.cluster_certificate_authority_data
}
output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}
