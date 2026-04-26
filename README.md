<<<<<<< HEAD
# retrogameshop-eks-infra
Production-grade AWS EKS infrastructure for RetroGameShop, automated with Terraform. Features a highly available VPC, managed node groups, and secure CI/CD integration. 
=======
```markdown
# 🎮 RetroGame EKS Infrastructure

Production-grade EKS infrastructure for the RetroGame microservices platform, built with Terraform and GitHub Actions.

## 🏗️ Architecture

```
GitHub Actions CI/CD
        ↓
Docker Images → DockerHub
        ↓
GitOps → retrogame-k8s-manifests repo
        ↓
ArgoCD → EKS Cluster
        ↓
Microservices running on Kubernetes
```

## 🛠️ Tech Stack

| Tool | Purpose |
|---|---|
| Terraform | Infrastructure as Code |
| AWS EKS | Managed Kubernetes |
| Karpenter | Node autoscaling |
| ArgoCD | GitOps deployments |
| ALB Controller | Load balancing |
| Prometheus + Grafana | Monitoring |
| GitHub Actions | CI/CD pipeline |

## 📁 Repository Structure

```
retrogame-eks-infra/
├── envs/
│   └── prod/
│       ├── main.tf         # VPC + EKS + Addons
│       ├── kubernetes.tf   # Karpenter + ArgoCD secret
│       ├── version.tf      # Providers + S3 backend
│       ├── variables.tf    # Input variables
│       └── terraform.tfvars # Production values
├── modules/
│   ├── vpc/          # VPC, subnets, NAT gateway
│   └── eks/          # EKS cluster, node groups, OIDC
├── application.yaml  # ArgoCD app pointing to manifests repo
├── ingress.yaml      # ALB ingress for all services
└── .github/
    └── workflows/
        └── terraform.yaml  # CI/CD pipeline
```
## 🚀 Infrastructure Components

### VPC
- Multi-AZ setup across 3 availability zones
- Public and private subnets
- NAT Gateway for private subnet internet access
- Subnet tagging for ALB controller and Karpenter

### EKS Cluster
- Kubernetes 1.31
- Managed node groups
- OIDC provider for IRSA
- Pod Identity for modern IAM integration
- API authentication mode

### Cluster Addons (EKS Blueprints)
- **AWS Load Balancer Controller** — ingress and ALB management
- **ArgoCD** — GitOps continuous deployment
- **Kube Prometheus Stack** — metrics and monitoring
- **Metrics Server** — HPA support

### Karpenter
- Intelligent node autoscaling
- Spot and On-Demand instance support
- Automatic node consolidation
- Cost optimization

## 🔄 GitOps Flow

```
Developer pushes code
        ↓
GitHub Actions builds and tests
        ↓
Docker image pushed to DockerHub
        ↓
CI updates image tag in manifests repo
        ↓
ArgoCD detects change
        ↓
ArgoCD deploys to EKS automatically
```

## 🔧 Prerequisites

- AWS CLI configured
- Terraform >= 1.0
- kubectl

## 🚀 Deployment

### 1. Create S3 backend and DynamoDB
```bash
aws s3api create-bucket \
  --bucket retrogame-tfstate-573986291693 \
  --region us-east-1

aws dynamodb create-table \
  --table-name retrogame-terraform-locks \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region us-east-1
```

### 2. Deploy infrastructure
```bash
cd envs/prod
terraform init
terraform plan -out=retrogame-prod.tfplan
terraform apply retrogame-prod.tfplan
```

### 3. Configure kubectl
```bash
aws eks update-kubeconfig \
  --region us-east-1 \
  --name retrogame-eks
```

### 4. Apply ArgoCD application
```bash
kubectl apply -f application.yaml
kubectl apply -f ingress.yaml
```

## 📊 Microservices

| Service | Language | Port |
|---|---|---|
| Frontend | Node.js | 3000 |
| Cart Service | Python | 8081 |
| Product Service | Go | 8080 |
| Order Service | Java | 8080 |
| Payment Service | C# | 8080 |
| Notification Service | Python | 8000 |

## 🔗 Related Repositories

- [RetroGame Microservices](https://github.com/Edwin-Oghenetejiri1/retrogame-microservices-k8s)
- [RetroGame K8s Manifests](https://github.com/Edwin-Oghenetejiri1/retrogame-k8s-manifests)
```
>>>>>>> 920bddd (new infra repo)
