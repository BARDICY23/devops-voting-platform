# Platform

This directory contains everything needed to run the project in a **cloud-first, production-ready** way:

- GitOps with **Argo CD** (App of Apps)
- Cluster add-ons (monitoring, external-secrets, image updater)
- Kubernetes deployment of the voting app via **Helm**
- Terraform to provision EKS + VPC

## Quick start (high level)

### 1) Provision a cluster

Terraform is under:

- `infra/terraform/envs/dev`

### 2) Install Argo CD

Install Argo CD in the `argocd` namespace (Helm is recommended).

### 3) Bootstrap GitOps (App of Apps)

From repo root:

```bash
kubectl apply -f platform/platform/argocd/bootstrap/app-of-apps.yaml
```

Argo will then sync:

- `platform-base` (namespaces + PSA labels)
- monitoring stack
- external-secrets operator
- image updater
- voting app (dev)

## Cloud-first notes

- In AWS/EKS, ingress is handled by **AWS Load Balancer Controller (ALB)**.
- PostgreSQL passwords are expected from a Kubernetes Secret (created by External Secrets in cloud).
  - Local/dev uses a plaintext Secret via `values-dev.yaml` to keep iteration fast.
