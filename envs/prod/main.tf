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
#                                      AWS LOAD BALANCER CONTROLLER                                     #
#########################################################################################################
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  wait       = true
  depends_on = [module.eks]

  set {
    name  = "clusterName"
    value = module.eks.cluster_name
  }
  set {
    name  = "serviceAccount.create"
    value = "true"
  }
  set {
    name  = "region"
    value = var.region
  }
  set {
    name  = "vpcId"
    value = module.vpc.vpc_id
  }
}

#########################################################################################################
#                                      METRICS SERVER                                                   #
#########################################################################################################
resource "helm_release" "metrics_server" {
  name       = "metrics-server"
  repository = "https://kubernetes-sigs.github.io/metrics-server/"
  chart      = "metrics-server"
  namespace  = "kube-system"
  wait       = true
  depends_on = [module.eks]
}

#########################################################################################################
#                                      ARGOCD                                                           #
#########################################################################################################
resource "helm_release" "argocd" {
  name             = "argo-cd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  wait             = true
  depends_on       = [helm_release.alb_controller]

  set {
    name  = "server.insecure"
    value = "true"
  }
}

#########################################################################################################
#                                      KARPENTER                                                        #
#########################################################################################################
resource "helm_release" "karpenter" {
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "1.6.0"
  namespace        = "karpenter"
  create_namespace = true
  wait             = false
  depends_on       = [module.eks]

  set {
    name  = "settings.clusterName"
    value = module.eks.cluster_name
  }
  set {
    name  = "settings.clusterEndpoint"
    value = module.eks.cluster_endpoint
  }
  set {
    name  = "serviceAccount.name"
    value = "karpenter"
  }
  set {
    name  = "env[0].name"
    value = "AWS_REGION"
  }
  set {
    name  = "env[0].value"
    value = var.region
  }
}

#########################################################################################################
#                                      KARPENTER NODE CLASS                                             #
#########################################################################################################
resource "kubectl_manifest" "karpenter_node_class" {
  yaml_body = <<-YAML
    apiVersion: karpenter.k8s.aws/v1
    kind: EC2NodeClass
    metadata:
      name: default
    spec:
      amiSelectorTerms:
        - alias: "al2023@latest"
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

#########################################################################################################
#                                      KARPENTER NODE POOL                                             #
#########################################################################################################
resource "kubectl_manifest" "karpenter_node_pool" {
  yaml_body = <<-YAML
    apiVersion: karpenter.sh/v1
    kind: NodePool
    metadata:
      name: default
    spec:
      template:
        spec:
          nodeClassRef:
            group: karpenter.k8s.aws
            kind: EC2NodeClass
            name: default
          requirements:
            - key: "karpenter.sh/capacity-type"
              operator: In
              values: ["spot", "on-demand"]
            - key: "kubernetes.io/arch"
              operator: In
              values: ["amd64"]
            - key: "kubernetes.io/os"
              operator: In
              values: ["linux"]
            - key: "karpenter.k8s.aws/instance-category"
              operator: In
              values: ["c", "m", "r"]
            - key: "karpenter.k8s.aws/instance-generation"
              operator: Gt
              values: ["2"]
          expireAfter: 720h
      limits:
        cpu: 1000
      disruption:
        consolidationPolicy: WhenEmptyOrUnderutilized
        consolidateAfter: 1m
  YAML

  depends_on = [kubectl_manifest.karpenter_node_class]
}

#########################################################################################################
#                                      ARGOCD REPO SECRET                                               #
#########################################################################################################
resource "kubernetes_secret" "argo_repo" {
  metadata {
    name      = "retrogame-repo"
    namespace = "argocd"
    labels = {
      "argocd.argoproj.io/secret-type" = "repository"
    }
  }

  data = {
    url     = var.repo_url
    project = "default"
    type    = "git"
  }

  depends_on = [helm_release.argocd]
}

#########################################################################################################
#                                      APP NAMESPACE                                                    #
#########################################################################################################
resource "kubernetes_namespace" "retrogame" {
  metadata {
    name = "retrogame"
  }

  depends_on = [module.eks]
}











