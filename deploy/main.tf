locals {
  kube_config = "~/.kube/config"
}

provider "kubernetes" {
  config_context_cluster   = "minikube"
  config_path = local.kube_config
}
provider "helm" {
  kubernetes {
    config_path = local.kube_config
  }
}

################### Install http-server ###################

# A Release is an instance of a chart running in a Kubernetes cluster.
resource "helm_release" "http-server" {
  namespace  = "default"
  name       = "httpserver"
  # Locally load Helm chart
  chart      = "${path.module}/http_server"
  values = [
    file("${path.module}/minikube-values.yaml")
  ]
}