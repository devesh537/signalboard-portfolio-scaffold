terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.14"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.31"
    }
  }
}

resource "kubernetes_namespace" "monitoring" {
  metadata {
    name = "monitoring"
  }
}

# kube-prometheus-stack bundles Prometheus + Grafana + Alertmanager +
# node/kube-state metrics in one chart — avoids hand-rolling each piece.
resource "helm_release" "kube_prometheus_stack" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  version    = "62.7.0"
  namespace  = kubernetes_namespace.monitoring.metadata[0].name

  values = [
    yamlencode({
      grafana = {
        adminPassword = var.grafana_admin_password
      }
      prometheus = {
        prometheusSpec = {
          retention = var.prometheus_retention
        }
      }
    })
  ]
}

# Custom app-specific alert rules from observability/prometheus/alert-rules.yaml,
# loaded as a PrometheusRule CR so the Prometheus Operator picks them up
# automatically alongside the chart's built-in rules.
resource "kubernetes_manifest" "signalboard_alert_rules" {
  manifest = yamldecode(file("${path.module}/../../../observability/prometheus/alert-rules.yaml"))
  depends_on = [helm_release.kube_prometheus_stack]
}
