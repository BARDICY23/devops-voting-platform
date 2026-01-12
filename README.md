# Kubernetes Voting Application (Helm + Zero-Trust NetworkPolicy)

This repo contains a microservices voting app with:
- Local development via Docker Compose
- Kubernetes deployment via Helm (with Redis + PostgreSQL subcharts)
- Security posture aligned with PSA (non-root) and NetworkPolicies (zero-trust default deny)
- Optional (disabled-by-default) availability/scaling features: PDB/HPA/topology spread

## Repo layout

- `services/` — application services + Dockerfiles
- `platform/compose.yaml` — local orchestration
- `platform/apps/helm/voting-app/` — Helm chart
- `platform/infra/terraform/` — cluster/IaC (dev env example)
- `platform/platform/` — cluster add-ons (ingress, monitoring, external-secrets, argo)

## Local (Docker Compose)

Run the app:
```bash
docker compose -f platform/compose.yaml up --build
```

(Optional) seed data profile:
```bash
docker compose -f platform/compose.yaml --profile seed up --build
```

Vote UI: http://localhost:8080  
Results UI: http://localhost:8081

## Kubernetes (Helm)

Build/push images, then install (example):
```bash
helm upgrade --install voting-app platform/apps/helm/voting-app \
  --namespace voting --create-namespace \
  --set vote.image.tag=<TAG> \
  --set result.image.tag=<TAG> \
  --set worker.image.tag=<TAG> \
  --set seed.image.tag=<TAG>
```

Port-forward:
```bash
kubectl -n voting port-forward svc/vote 8080:80
kubectl -n voting port-forward svc/result 8081:80
```

## Notes

- ServiceMonitor is kept as reference but disabled by default (no `/metrics` endpoints yet).
- Seed job is env-driven and PSA-safe; job cleanup/timeouts are configurable in `values.yaml`.
- PDB/HPA/topology spread are present but disabled by default.
