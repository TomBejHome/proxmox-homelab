terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.12.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.25.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.14.0"
    }
  }
}

provider "helm" {
  kubernetes {
    config_path = "../01-infrastructure/kubeconfig.yaml"
  }
}

provider "kubernetes" {
  config_path = "../01-infrastructure/kubeconfig.yaml"
}

# Tohle ti tam chybělo - kubectl musí taky vědět, kde je kubeconfig!
provider "kubectl" {
  config_path = "../01-infrastructure/kubeconfig.yaml"
}