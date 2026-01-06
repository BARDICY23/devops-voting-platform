# TQP – Voting App DevOps (Production-Grade)

This repository implements a **secure, observable, scalable** cloud setup for the multi-service voting application (vote/result/worker/seed-data) using:
- **Docker Compose** for local parity
- **Kubernetes-first deployment via Helm** (authoritative source of truth)
- **GitOps with Argo CD**
- **Observability**: Prometheus + Grafana (kube-prometheus-stack), app ServiceMonitors, alert rules
- **Security**: non-root, seccomp, dropped caps, NetworkPolicies, PSA labels
- **CI/CD**: GitHub Actions (build, scan, helm lint/template, deploy to ephemeral kind, smoke tests)

> Cloud target can be **AKS** (per quest description) or **EKS** with small Terraform adjustments. The Terraform here provides an **AKS dev environment skeleton** and is structured for multi-env.

---

## Repo Layout

```
apps/
  helm/
    voting-app/                # Helm chart (authoritative for app)
infra/
  terraform/
platform/
  argocd/                      # GitOps apps
  helm/                        # platform add-ons values (ingress, monitoring, etc.)
  namespaces.yaml
  psa-labels.yaml
services/                      # Application source (placeholder: bring from upstream)
compose.yaml                   # Local dev only
.github/workflows/             # CI pipelines
```

---

## Local: Docker Compose (end-to-end)

### Requirements
- Docker + Docker Compose v2

### Run
```bash
docker compose -f compose.yaml up --build
```

- vote: http://localhost:8080
- result: http://localhost:8081

---

## Local: Kubernetes (kind) – quick validation

### Requirements
- kubectl, helm
- kind

```bash
make kind-up
make platform-install   # ingress-nginx + monitoring stack (optional)
make app-install
```

Then:
```bash
curl -H "Host: vote.local"   http://$(kubectl -n ingress-nginx get svc ingress-nginx-controller -o jsonpath='{.status.loadBalancer.ingress[0].ip}')/
```

(You can also port-forward ingress controller or use `localhost` depending on your setup.)

---

## GitOps: Argo CD

1) Install Argo CD:
```bash
kubectl create ns argocd
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd -n argocd
```

2) Apply app-of-apps:
```bash
kubectl apply -f platform/argocd/apps/app-of-apps.yaml
```

Argo CD will deploy:
- namespaces + PSA labels
- ingress-nginx
- kube-prometheus-stack
- voting-app (Helm)

---

## Monitoring & Alerts

### What you get
- **Cluster metrics** (nodes/pods/resources) via kube-prometheus-stack
- **App scraping** via ServiceMonitor resources in the chart (can be disabled)
- **Alerts** via PrometheusRule resources in the chart

### App metrics
This repo includes **ServiceMonitors** expecting services to expose Prometheus metrics on:
- `vote`: `http://<svc>:8080/metrics`
- `result`: `http://<svc>:8081/metrics`

If your upstream app does not expose metrics yet, set:
```yaml
monitoring:
  enabled: false
```

---

## Security Model

- Non-root containers
- `seccompProfile: RuntimeDefault`
- Drop Linux capabilities
- `allowPrivilegeEscalation: false`
- Namespace PSA labels (restricted baseline)
- NetworkPolicies:
  - default deny ingress/egress
  - explicit allow paths between app -> redis/postgres
  - explicit allow ingress-nginx -> vote/result

---

## CI/CD

Workflows:
- Build & push images to GHCR
- Trivy scans (images + filesystem)
- Helm lint/template
- Deploy to ephemeral kind cluster
- Smoke tests

---

## Trade-offs

- **Local validation** uses kind for speed; cloud provisioning is separated in Terraform (AKS skeleton).
- **Postgres/Redis** are deployed via Helm dependencies (Bitnami) in final flow; manifests are provided for reference under `apps/helm/voting-app/reference-manifests/`.

---

## Next improvements (if more time)
- External Secrets Operator + Key Vault/AWS Secrets Manager
- SLO-based alerts and dashboards
- Canary/blue-green via Argo Rollouts
- mTLS service mesh (Linkerd/Istio)
