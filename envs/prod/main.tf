#########################################################################################################
#                                      VPC                                                              #
#########################################################################################################
module "vpc" {
  source = "../../modules/vpc"

  env                  = var.env
  vpc_name             = var.vpc_name
  cluster_name         = var.cluster_name
  azs                  = var.azs
  vpc_cidr             = var.vpc_cidr
  private_subnets_cidr = var.private_subnets_cidr
  public_subnets_cidr  = var.public_subnets_cidr
}

#########################################################################################################
#                                      EKS                                                              #
#########################################################################################################
module "eks" {
  source     = "../../modules/eks"
  depends_on = [module.vpc]

  cluster_name       = var.cluster_name
  eks_version        = var.eks_version
  subnet_ids         = module.vpc.private_subnet_ids
  admin_arn          = var.admin_arn
  principal_arn      = var.principal_arn
  principal_arn_name = var.principal_arn_name
  node_groups        = var.node_groups
}

#########################################################################################################
#                                      EKS BLUEPRINTS ADDONS                                            #
#########################################################################################################
module "eks_blueprints_addons" {
  source     = "aws-ia/eks-blueprints-addons/aws"
  version    = "~> 1.0"
  depends_on = [module.eks]

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  # Core addons
  eks_addons = {}

  # ALB Controller — needed for ingress + Route 53
  enable_aws_load_balancer_controller = true
  aws_load_balancer_controller = {
    set = [
      {
        name  = "vpcId"
        value = module.vpc.vpc_id
      }
    ]
  }

  # Metrics server — needed for HPA
  enable_metrics_server = true

  # ArgoCD — GitOps
  enable_argocd = true

  # Prometheus + Grafana — monitoring
  enable_kube_prometheus_stack = false

  tags = {
    Environment = var.env
  }
}

#########################################################################################################
#                                      KARPENTER                                                        #
#########################################################################################################
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.0"

  cluster_name                    = module.eks.cluster_name
  namespace                       = "karpenter"
  enable_pod_identity             = true
  create_pod_identity_association = true

  tags = {
    Environment = var.env
  }
}




