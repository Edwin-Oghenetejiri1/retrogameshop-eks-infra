#########################################################################################################
#                                      AWS LOAD BALANCER CONTROLLER                                     #
#########################################################################################################
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  wait       = true

  set {
    name  = "clusterName"
    value = data.terraform_remote_state.infra.outputs.cluster_name
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
    value = data.terraform_remote_state.infra.outputs.vpc_id
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
#                                      KARPENTER IAM                                                    #
#########################################################################################################
module "karpenter" {
  source  = "terraform-aws-modules/eks/aws//modules/karpenter"
  version = "~> 20.0"

  cluster_name                    = data.terraform_remote_state.infra.outputs.cluster_name
  namespace                       = "karpenter"
  enable_pod_identity             = true
  create_pod_identity_association = true

  tags = {
    Environment = var.env
  }
}

#########################################################################################################
#                                      KARPENTER HELM                                                   #
#########################################################################################################
resource "helm_release" "karpenter" {
  name             = "karpenter"
  repository       = "oci://public.ecr.aws/karpenter"
  chart            = "karpenter"
  version          = "1.6.0"
  namespace        = "karpenter"
  create_namespace = true
  wait             = false
  depends_on       = [module.karpenter]

  set {
    name  = "settings.clusterName"
    value = data.terraform_remote_state.infra.outputs.cluster_name
  }
  set {
    name  = "settings.clusterEndpoint"
    value = data.terraform_remote_state.infra.outputs.cluster_endpoint
  }
  set {
    name  = "serviceAccount.name"
    value = module.karpenter.service_account
  }
  set {
    name  = "settings.interruptionQueue"
    value = module.karpenter.queue_name
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
      role: "${module.karpenter.node_iam_role_name}"
      subnetSelectorTerms:
        - tags:
            karpenter.sh/discovery: "${data.terraform_remote_state.infra.outputs.cluster_name}"
      securityGroupSelectorTerms:
        - tags:
            karpenter.sh/discovery: "${data.terraform_remote_state.infra.outputs.cluster_name}"
  YAML

  depends_on = [helm_release.karpenter]
}

#########################################################################################################
#                                      KARPENTER NODE POOL                                              #
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
}

#########################################################################################################
#                                      PROMETHEUS + GRAFANA                                             #
#########################################################################################################
resource "helm_release" "kube_prometheus_stack" {
  name             = "kube-prometheus-stack"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  wait             = true
  depends_on       = [helm_release.alb_controller]

  set {
    name  = "grafana.adminPassword"
    value = var.grafana_password
  }

  # Grafana ingress via ALB
  set {
    name  = "grafana.ingress.enabled"
    value = "false"
  }
  set {
    name  = "grafana.ingress.ingressClassName"
    value = "alb"
  }
  set {
    name  = "grafana.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/scheme"
    value = "internet-facing"
  }
  set {
    name  = "grafana.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/target-type"
    value = "ip"
  }
  set {
    name  = "grafana.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/listen-ports"
    value = "[{\"HTTP\": 80}]"
  }
  set {
    name  = "grafana.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/healthcheck-path"
    value = "/api/health"
  }
  set {
    name  = "grafana.ingress.annotations.alb\\.ingress\\.kubernetes\\.io/success-codes"
    value = "200"
  }
  set {
    name  = "grafana.ingress.paths[0]"
    value = "/"
  }

  # Scrape retrogame namespace
  set {
    name  = "prometheus.prometheusSpec.podMonitorNamespaceSelector.matchLabels.monitoring"
    value = "true"
  }
  set {
    name  = "prometheus.prometheusSpec.serviceMonitorNamespaceSelector.matchLabels.monitoring"
    value = "true"
  }
}