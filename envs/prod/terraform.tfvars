region       = "us-east-1"
env          = "prod"
vpc_name     = "retrogame-vpc"
cluster_name = "retrogame-eks"
eks_version  = "1.32"

vpc_cidr             = "10.0.0.0/16"
azs                  = ["us-east-1a", "us-east-1b", "us-east-1c"]
private_subnets_cidr = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
public_subnets_cidr  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

admin_arn          = "arn:aws:iam::573986291693:user/Tobi"
principal_arn      = "arn:aws:iam::573986291693:user/Tobi"
principal_arn_name = "pipeline"

node_groups = {
  general = {
    instance_types = ["t3.small"]
    capacity_type  = "ON_DEMAND"
    scaling_config = {
      desired_size = 3
      max_size     = 5
      min_size     = 1
    }
  }
}
repo_url = "https://github.com/Edwin-Oghenetejiri1/retrogame-k8s-manifests.git"