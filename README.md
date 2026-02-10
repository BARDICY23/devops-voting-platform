# Voting App — Cloud-first DevOps/GitOps Repo

This repo contains a microservices voting app that’s been upgraded with a **production-grade platform layer**:

- Docker images for each service (`services/*`)
- Local run via Docker Compose (`platform/compose.yaml`)
- Kubernetes deployment via Helm (`platform/apps/helm/voting-app`)
- GitOps delivery via Argo CD App-of-Apps (`platform/platform/argocd`)
- Observability add-ons (Prometheus/Grafana) + curated dashboards/alerts (`platform/platform/observability`)

## Repo layout

- `services/` — application code + Dockerfiles (vote/result/worker/seed-data)
- `.github/workflows/services-ci.yaml` — builds + pushes images to Docker Hub
- `platform/compose.yaml` — local dev orchestration (fast iteration)
- `platform/apps/helm/voting-app/` — Helm chart (includes Redis + PostgreSQL deps)
- `platform/platform/` — GitOps platform layer (Argo apps + observability resources)
- `platform/infra/terraform/` — Terraform for EKS/VPC (dev env example)

## GitOps bootstrap

1) Install Argo CD in the `argocd` namespace (Helm recommended).

2) Apply the root App of Apps:

```bash
kubectl apply -f platform/platform/argocd/bootstrap/app-of-apps.yaml
```

After that, Argo CD manages everything under `platform/platform/argocd/apps/`.

## Security posture (what’s already here)

- PSA-ready: app pods run non-root + RuntimeDefault seccomp
- Default-deny NetworkPolicies + explicit allow rules
- DB passwords consumed from Kubernetes Secret (cloud-first contract)
