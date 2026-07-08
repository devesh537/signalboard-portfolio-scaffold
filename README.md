# Signalboard — Self-Operated 3-Tier Platform on AWS EKS

A small blog-style app (React + Node/Express + Postgres) used as the
vehicle for a real DevOps/SRE platform: Terraform-provisioned EKS,
GitOps delivery via Argo CD, a security-gated CI pipeline, and
Prometheus-based monitoring with SLOs and alerting.

## Architecture

```
                        Route53 / LoadBalancer
                                 │
                    ┌────────────▼────────────┐
                    │       EKS (Auto Mode)     │
                    │  ┌─────────┐  ┌─────────┐ │  ┌─────────────┐
                    │  │frontend │─▶│ backend │─┼─▶│  postgres    │
                    │  │(2 pods) │  │(2 pods) │ │  │ (1 replica)  │
                    │  └─────────┘  └─────────┘ │  └─────────────┘
                    │   NetworkPolicies restrict pod-to-pod traffic
                    └──────────┬─────────────────┘
                               │ /metrics scraped
                    ┌──────────▼─────────────┐
                    │ Prometheus + Alertmanager│
                    │        + Grafana          │
                    └────────────────────────────┘
```

## End-to-end workflow

**1. Provisioning (Terraform, run once per environment via `scripts/bootstrap.sh`)**
`infra/envs/dev` wires together three modules: `vpc` (network), `eks`
(cluster, Auto Mode), `monitoring` (installs kube-prometheus-stack via
Helm and loads `observability/prometheus/alert-rules.yaml` as a
`PrometheusRule`). State is remote (S3 + DynamoDB lock), config in
`backend.hcl`. Bootstrap also installs Argo CD and applies the
app-of-apps — that's the last manual step; everything after is automatic.

**2. Code → image (CI, `.github/workflows/ci-cd.yml`)**
Push to `app/backend` or `app/frontend` triggers: lint/test → `npm audit`
→ Docker build & push to GHCR (tagged with the git SHA) → Trivy image
scan → Checkov scan on `infra/` and `gitops/base/`. CI never holds
cluster credentials — its last step only edits `gitops/overlays/dev`
(`kustomize edit set image ...`) and pushes that commit.

**3. Delivery (Argo CD, running in-cluster, not in CI)**
Argo CD watches `gitops/overlays/dev`. When the image tag commit lands,
it diffs desired vs. live state and syncs automatically. `selfHeal: true`
means if someone hand-edits the cluster, Argo CD reverts it — Git stays
the single source of truth. This is why CI doesn't need `kubectl` access
at all.

**4. Observability (continuous)**
The backend exposes `/metrics` (via `prom-client`) — request count,
latency histogram. `observability/prometheus/alert-rules.yaml` defines
two-window burn-rate alerts against a 99.5% availability SLO (fast burn
= page, slow burn = ticket — avoids paging on brief blips while still
catching a fast outage early), a p95 latency alert, and a Postgres
connection-saturation alert.

**5. Teardown (`scripts/teardown.sh`)**
Deletes the Argo CD Application first (so any LB/PV it created is
cleaned up), waits for finalizers, then `terraform destroy`. Order
matters — destroying Terraform first orphans anything Argo CD created
that Terraform doesn't know about.

## Repo layout

```
app/backend/     Node.js + Express API, Postgres client, /metrics endpoint
app/frontend/    React (Vite) UI, built and served via nginx
infra/modules/   vpc, eks, monitoring — reusable Terraform modules
infra/envs/dev/  wires the modules together for one environment
gitops/base/     Kustomize base manifests (namespace, db, backend, frontend, netpols)
gitops/overlays/ per-environment patches (this is what CI updates on every deploy)
gitops/argocd/   app-of-apps + per-env Argo CD Application definitions
observability/   Prometheus alert rules (PrometheusRule CRD)
.github/workflows/ the CI/CD pipeline described above
scripts/         bootstrap.sh / teardown.sh
docker-compose.yml  local dev without Kubernetes
```

## Running it locally (no cluster needed)

```bash
docker compose up --build
# frontend: http://localhost:8080   backend: http://localhost:5000/api/health
```

## Running it on real AWS

```bash
export TF_VAR_grafana_admin_password="something-not-committed"
./scripts/bootstrap.sh dev
```

## Design decisions (short version)

- **EKS Auto Mode over self-managed nodes/Karpenter**: this cluster gets
  stood up and torn down between working sessions rather than run 24/7.
  Auto Mode removes node lifecycle management entirely, at the cost of
  less control over node-level config — a tradeoff I'd revisit for a
  long-running production cluster.
- **Separate Terraform state per environment** (not workspaces): a bad
  `apply` in dev should be structurally unable to touch staging/prod
  state. Workspaces share backend config in a way that makes that
  mistake too easy.
- **CI updates GitOps, never the cluster directly**: keeps cluster
  credentials out of GitHub Actions secrets entirely; Argo CD is the only
  thing with cluster-admin.
- **DB connection pool size is environment-configurable** (`DB_POOL_MAX`),
  not hardcoded — this came out of hitting real pool exhaustion during a
  local load test (`hey -z 2m -c 50 .../api/posts`): 2 replicas × default
  pool size of 10 saturated Postgres almost immediately under 50
  concurrent clients. Fix: made it configurable per environment and added
  the `SignalboardDBConnectionsNearMax` alert as a leading indicator
  instead of only alerting on the resulting latency symptom.

## SLO

99.5% availability / 95% of requests under 300ms p95, rolling 30-day
window. Two-window burn-rate alerting (fast: >14.4x over 5m+1h → page;
slow: >6x over 6h+3d → ticket) — see `observability/prometheus/alert-rules.yaml`.

## What I'd change for real production scale

Multi-AZ NAT (one per AZ, not single), Karpenter instead of Auto Mode for
finer bin-packing and spot mixing, External Secrets Operator instead of
plain K8s Secrets, and a staging/prod promotion gate in CI rather than
auto-syncing straight to a single environment.
