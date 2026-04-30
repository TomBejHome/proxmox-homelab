resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }
}

resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  namespace  = kubernetes_namespace_v1.argocd.metadata[0].name
  version    = "7.7.0"

  set {
    name  = "server.extraArgs"
    value = "{--insecure}"
  }
}


resource "kubectl_manifest" "argocd_root_app" {
  yaml_body = <<YAML
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: root-app
  namespace: argocd
spec:
  project: default
  source:
    repoURL: 'https://github.com/TomBejHome/proxmox-homelab.git'
    path: root-app
    targetRevision: HEAD
    path: kubernetes/infrastructure/appsets
  destination:
    server: 'https://kubernetes.default.svc'
    namespace: argocd
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
YAML

  depends_on = [helm_release.argocd]
}