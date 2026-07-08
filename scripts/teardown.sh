#!/usr/bin/env bash
# Tears down in dependency order: Argo CD apps first (so LBs/PVs they
# created are cleaned up), then Terraform. Prevents orphaned ELBs/EBS
# volumes that terraform destroy won't know about.
# Usage: ./scripts/teardown.sh dev
set -euo pipefail

ENV="${1:?usage: teardown.sh <dev|staging|prod>}"

echo "==> Deleting Argo CD-managed application first"
kubectl delete -f "gitops/argocd/apps/${ENV}/app.yaml" --ignore-not-found
sleep 30

echo "==> Destroying Terraform-managed infra for env: ${ENV}"
cd "infra/envs/${ENV}"
terraform destroy -auto-approve

echo "==> Done."
