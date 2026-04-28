terraform {
  backend "s3" {
    bucket         = "retrogame-tfstate-573986291693"
    key            = "prod/infra/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "retrogame-terraform-locks"
    encrypt        = true
  }

  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
    time = {
      source  = "hashicorp/time"
      version = "~> 0.9"
    }
  }
}

provider "aws" {
  region = var.region
}

provider "aws" {
  alias  = "virginia"
  region = "us-east-1"
}

data "aws_region" "current" {}