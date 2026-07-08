#!/usr/bin/env bash
set -euo pipefail

ENV="${1:-dev}"

AWS_REGION="us-east-1"
CLUSTER_NAME="signalboard-dev"

echo "==> Updating kubeconfig"
aws eks update-kubeconfig \
  --region "${AWS_REGION}" \
  --name "${CLUSTER_NAME}"

echo "==> Creating argocd namespace"
kubectl create namespace argocd --dry-run=client -o yaml | kubectl apply -f -

echo "==> Installing Argo CD"
kubectl apply -n argocd \
  -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

echo "==> Waiting for Argo CD..."
kubectl rollout status deployment/argocd-server \
  -n argocd \
  --timeout=300s

echo "==> Applying App of Apps"
kubectl apply -f gitops/argocd/app-of-apps.yaml

echo "Bootstrap complete."
