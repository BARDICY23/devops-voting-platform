# Platform (GitOps)

This folder contains the **platform layer** (Argo CD apps + cluster add-ons) that makes the project production-ready.

## Layout

- `platform/base/`
  - Cluster baseline resources (namespaces, PSA labels, etc.)
- `platform/argocd/`
  - `bootstrap/` → the **one** manifest you apply manually to bootstrap GitOps (App of Apps)
  - `apps/` → Argo CD `Application` resources managed by the root app
- `observability/helm/monitoring-resources/`
  - Dashboards + PrometheusRules that complement kube-prometheus-stack

## Bootstrap flow

1) Install Argo CD (one time) in the `argocd` namespace.

2) Apply the root App of Apps:

```bash
kubectl apply -f platform/argocd/bootstrap/app-of-apps.yaml
```

After that, Argo CD manages everything under `platform/argocd/apps/`.

## Notes

- We target **AWS/EKS** for production, so ingress is ALB-based (AWS Load Balancer Controller).
- Local clusters (kind/minikube) are for iteration only — the repo is designed cloud-first.
