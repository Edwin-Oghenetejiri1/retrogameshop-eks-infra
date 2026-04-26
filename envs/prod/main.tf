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
#                                 HELM ADDONS (THE BOOTSTRAP)                                           #
#########################################################################################################

# 1. AWS Load Balancer Controller
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://github.io"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  wait       = true

  # FIXED: Syntax for Helm Provider v3.x
  set = [
    {
      name  = "clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "serviceAccount.create"
      value = "true"
    },
    {
      name  = "region"
      value = var.region
    },
    {
      name  = "vpcId"
      value = module.vpc.vpc_id
    }
  ]
}

# 2. Metrics Server
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://github.io"
  chart      = "metrics-server"
  namespace  = "kube-system"
  wait       = true
}

# 3. ArgoCD
resource "helm_release" "argocd" {
  name             = "argo-cd"
  repository       = "https://github.io"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  wait             = true

  set = [
    {
      name  = "server.insecure"
      value = "true"
    }
  ]
}

# 4. Karpenter
resource "helm_release" "karpenter" {
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "1.0.1"
  namespace        = "karpenter"
  create_namespace = true

  set = [
    {
      name  = "settings.clusterName"
      value = module.eks.cluster_name
    },
    {
      name  = "settings.clusterEndpoint"
      value = module.eks.cluster_endpoint
    },
    {
      name  = "serviceAccount.name"
      value = "karpenter"
    }
  ]
}

#########################################################################################################
#                                 KARPENTER DEFAULT PROVISIONER                                         #
#########################################################################################################

resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1beta1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiFamily: AL2
      role: "${var.cluster_name}-node-role"
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: "${module.eks.cluster_name}"
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: "${module.eks.cluster_name}"
  YAML

  depends_on = [helm_release.karpenter]
}

resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1beta1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            name: default
          requirements:
            - key: "karpenter.sh/capacity-type"
              operator: In
              values: ["spot", "on-demand"]
            - key: "kubernetes.io/arch"
              operator: In
              values: ["amd64"]
  YAML

  depends_on = [kubectl_manifest.karpenter_node_class]
}



