# Voting App — Production-Grade DevOps Platform

> A microservices voting application used as a vehicle to build and demonstrate a complete,
> production-grade DevOps/GitOps platform on AWS EKS.
> **Actively in development** — core platform is functional, observability and chaos engineering layers in progress.

---

## What this is

This is not just a voting app. The voting app (vote / result / worker / seed-data) is the workload —
the real project is the **platform layer** that runs it:

- Containerized with Docker, orchestrated with Kubernetes
- Deployed via GitOps using ArgoCD App-of-Apps
- Infrastructure provisioned with Terraform on AWS EKS
- Secrets managed with zero credentials in Git via External Secrets Operator
- CI/CD with path-based GitHub Actions — only builds what changed
- Security hardened at every layer: container, network, secret, and supply chain

Everything here reflects decisions I'd make in a real production environment,
with the tradeoffs documented so anyone reading the code understands the *why*, not just the *what*.

---

## Architecture

```
                        ┌─────────────────────────────────────┐
                        │           AWS EKS Cluster            │
                        │                                      │
   User ──► ALB ──────► │  vote (Flask)    result (Node.js)   │
                        │       │                │             │
                        │    Redis            PostgreSQL       │
                        │       │                │             │
                        │    worker (.NET) ───────┘            │
                        │                                      │
                        │  ArgoCD · ESO · KEDA · Prometheus    │
                        └─────────────────────────────────────┘
                                      │
                              AWS Secrets Manager
```

### Services

| Service | Language | Role |
|---------|----------|------|
| `vote` | Python / Flask | User-facing voting interface |
| `result` | Node.js | Real-time results via WebSocket |
| `worker` | .NET | Consumes Redis queue, writes to PostgreSQL |
| `seed-data` | Bash / Python | Populates test votes for dev/testing |

### Data flow

1. User casts vote → `vote` service writes to Redis queue
2. `worker` consumes from Redis → writes to PostgreSQL
3. `result` service reads PostgreSQL → pushes to browser via WebSocket

---

## Repository layout

```
.
├── services/                        # Application code + Dockerfiles
│   ├── vote/
│   ├── result/
│   ├── worker/
│   └── seed-data/
├── platform/
│   ├── apps/helm/voting-app/        # Helm chart (the main deliverable)
│   │   ├── templates/               # K8s manifests as Helm templates
│   │   ├── values.yaml              # Base values (production defaults)
│   │   ├── values-local.yaml        # Local / minikube overrides
│   │   ├── values-dev.yaml          # Dev EKS overrides
│   │   └── values-prod.yaml         # Production overrides
│   ├── gitops/
│   │   ├── argocd/
│   │   │   ├── bootstrap/           # Root App-of-Apps
│   │   │   └── apps/                # All ArgoCD Application manifests
│   │   └── base/                    # Namespaces, PSA labels, ExternalSecrets
│   ├── infra/terraform/envs/dev/    # EKS + VPC + IRSA via Terraform
│   ├── observability/               # Prometheus rules + Grafana dashboards
│   ├── local/compose.yaml           # Local dev via Docker Compose
│   └── scripts/                     # Helper scripts (kind, minikube)
└── .github/workflows/               # CI/CD pipelines
```

---

## Running locally (Docker Compose)

The fastest way to see the app working end-to-end. No Kubernetes needed.

```bash
# Clone the repo
git clone https://github.com/BARDICY23/devops-voting-platform.git
cd devops-voting-platform

# Start everything
docker compose -f platform/local/compose.yaml up --build

# Vote UI
open http://localhost:8080

# Results UI
open http://localhost:8081

# Seed test data (optional — runs 3000 votes via Apache Bench)
docker compose -f platform/local/compose.yaml --profile seed up seed-data
```

Services start in the right order automatically — Redis and PostgreSQL health checks
gate the vote, result, and worker services. The schema is created by a `db-init`
one-shot container before the worker starts.

---

## Deploying to Kubernetes (Helm)

### Prerequisites

- `kubectl` configured against your cluster
- `helm` 3.x installed
- A Kubernetes Secret named `voting-app-postgresql` already present in the `voting` namespace
  (created by ESO in production, manually in dev — see secrets section below)

### Install

```bash
# Add Bitnami repo for Redis + PostgreSQL subcharts
helm repo add bitnami https://charts.bitnami.com/bitnami
helm dependency build platform/apps/helm/voting-app

# Install to a local cluster (creates secrets automatically)
helm install voting-app platform/apps/helm/voting-app \
  --namespace voting \
  --create-namespace \
  -f platform/apps/helm/voting-app/values.yaml \
  -f platform/apps/helm/voting-app/values-local.yaml

# Verify everything is running
kubectl get pods -n voting
```

### Environment value files

| File | Used for | Notes |
|------|----------|-------|
| `values.yaml` | Base defaults | Production-safe defaults, monitoring off |
| `values-local.yaml` | Local / minikube | Creates secrets inline, NodePort ingress |
| `values-dev.yaml` | Dev EKS | ALB ingress, Image Updater annotations, KEDA on |
| `values-prod.yaml` | Production EKS | Full HA — multi-replica, PDB, HPA, KEDA, topology spread |

---

## Deploying to AWS EKS (GitOps)

### Step 1 — Provision infrastructure with Terraform

```bash
cd platform/infra/terraform/envs/dev

# Initialize (configure your S3 backend first — see backend.tf)
terraform init

# Review the plan
terraform plan -var-file=terraform.tfvars

# Apply
terraform apply -var-file=terraform.tfvars
```

This creates:
- VPC with public/private subnets across multiple AZs
- EKS cluster with managed node group
- IRSA roles for AWS Load Balancer Controller and External Secrets Operator
- Secrets Manager secret placeholders for PostgreSQL and Redis credentials

### Step 2 — Bootstrap ArgoCD

```bash
# Install ArgoCD (Helm recommended)
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  -f platform/gitops/helm/argocd-values.yaml

# Apply the root App-of-Apps — ArgoCD manages everything from here
kubectl apply -f platform/gitops/argocd/bootstrap/app-of-apps.yaml
```

After this, ArgoCD will automatically deploy in order:

| Sync wave | What deploys |
|-----------|-------------|
| Wave 5 | KEDA |
| Wave 10 | External Secrets Operator |
| Wave 20 | Monitoring (kube-prometheus-stack) |
| Wave 25 | Platform base (namespaces, PSA labels, ExternalSecrets) |
| Wave 30 | Voting app |

### Step 3 — Populate secrets in AWS Secrets Manager

Before the voting app can start, two secrets need to exist in AWS Secrets Manager:

```bash
# PostgreSQL credentials
aws secretsmanager create-secret \
  --name voting-app/postgres \
  --secret-string '{"postgres-password":"<strong-password>","user-password":"<strong-password>"}'

# Redis credentials
aws secretsmanager create-secret \
  --name voting-app/redis \
  --secret-string '{"password":"<strong-password>"}'
```

ESO will sync these into Kubernetes Secrets automatically. The pods will not start until
the secrets exist — this is intentional.

---

## CI/CD pipelines

Three GitHub Actions workflows, each with a specific responsibility:

### `ci-validate.yaml` — runs on every PR

Uses `dorny/paths-filter` to detect exactly what changed and only builds what's affected.

```
PR opened
  └── detect changes
        ├── services/vote/** changed?    → build + Trivy scan vote image
        ├── services/result/** changed?  → build + Trivy scan result image
        ├── services/worker/** changed?  → build + Trivy scan worker image
        └── services/seed-data/** changed? → build + Trivy scan seed image
```

Also runs:
- `gitleaks` — scans full git history for accidentally committed secrets
- `dependency-review` — checks new dependencies for known CVEs

### `platform-validate.yaml` — runs on PR when `platform/**` changes

```
platform/** changed
  └── validate-platform
        ├── Docker Compose config validation
        ├── Helm dependency build
        ├── Helm lint (base + local values)
        ├── Helm template render
        ├── kubeconform — validates against K8s 1.29 schema
        └── kube-score — security and reliability scoring
```

### `release.yaml` — runs on merge to main

Same path filtering — only pushes images for services that actually changed.
Rebuilds using GHA layer cache for speed, scans the pushed image with Trivy before declaring success.

```
merge to main
  └── detect changes
        ├── vote changed?   → build + push bardicy/voting-vote:<sha> + :latest
        ├── result changed? → build + push bardicy/voting-result:<sha> + :latest
        ├── worker changed? → build + push bardicy/voting-worker:<sha> + :latest
        └── seed changed?   → build + push bardicy/voting-seed-data:<sha> + :latest
```

ArgoCD Image Updater watches the registry and writes the new SHA tag back to Git,
triggering an automatic sync. Full GitOps loop — no manual intervention.

---

## Security design

Security was a first-class concern throughout, not an afterthought.

### Container security

Every pod runs with:

```yaml
securityContext:
  runAsNonRoot: true
  allowPrivilegeEscalation: false
  readOnlyRootFilesystem: true
  capabilities:
    drop: [ALL]
  seccompProfile:
    type: RuntimeDefault
```

`/tmp` is mounted as an `emptyDir` for services that need a writable path.
No container runs as root. No container can escalate privileges.

### Network security

Default-deny NetworkPolicies are applied to the `voting` namespace.
Explicit allow rules permit only the traffic each service actually needs:

- `vote` → Redis only
- `worker` → Redis + PostgreSQL
- `result` → PostgreSQL only
- No direct internet access from backend services

### Secrets

Zero credentials in Git. Ever. The contract:

```
AWS Secrets Manager
      │
      │  (IRSA — no static AWS keys)
      ▼
External Secrets Operator
      │
      │  (ExternalSecret CRD)
      ▼
Kubernetes Secret
      │
      │  (secretKeyRef in pod spec)
      ▼
Container environment variable
```

In local dev, `secrets.create: true` in `values-local.yaml` creates secrets inline
for convenience. In any real environment, `secrets.create: false` and ESO owns the secret.

### Supply chain

- Trivy scans every image on PR and after push to registry
- `gitleaks` runs as a pre-commit hook and in CI
- `dependency-review` catches vulnerable dependencies in PRs
- Image tags are commit SHAs — no floating `latest` in production deployments

---

## Key architectural decisions

**Why ArgoCD App-of-Apps over a single Application?**
Each platform component (ESO, monitoring, KEDA, the app itself) has its own lifecycle.
App-of-Apps lets them deploy independently with sync waves controlling order,
and lets you add new platform components without touching existing ones.

**Why External Secrets Operator over Sealed Secrets?**
Sealed Secrets encrypts secrets and stores them in Git — you still manage the encryption keys.
ESO keeps secrets entirely out of Git and integrates natively with AWS Secrets Manager,
including automatic rotation. In a cloud-native environment ESO is the cleaner model.

**Why KEDA over plain HPA for the worker?**
The worker's load is determined by queue depth, not CPU or memory.
A worker sitting idle consumes almost no CPU even when 1000 votes are queued.
KEDA scales on the actual business metric — Redis list length — which is both
more accurate and more responsive than resource-based autoscaling.

**Why Bitnami subcharts over standalone Redis/PostgreSQL deployments?**
Bitnami subcharts are production-tested, actively maintained, and handle
replication, persistence, and secret integration cleanly.
The tradeoff is less control over the exact manifest — acceptable for stateful dependencies
that aren't the core of what's being demonstrated here.

**Why a single NAT gateway in dev?**
Cost. A NAT gateway per AZ costs ~$100/month extra for a dev environment.
`single_nat_gateway = true` in Terraform — production would use `false`.

---

## What's in progress

This project is actively being developed. Completed and planned:

- [x] Docker Compose local dev
- [x] Helm chart with multi-environment values
- [x] ArgoCD App-of-Apps GitOps bootstrap
- [x] External Secrets Operator + AWS Secrets Manager integration
- [x] KEDA event-driven worker autoscaling
- [x] Path-based GitHub Actions CI with Trivy + kubeconform
- [x] Terraform EKS + VPC + IRSA
- [x] Pod security hardening + NetworkPolicies
- [x] ArgoCD AppProject with RBAC
- [ ] TLS via ACM + HTTPS-only ingress
- [ ] Prometheus metrics on vote and result services
- [ ] Grafana dashboards with real data
- [ ] SLOs with Sloth + error budget alerting
- [ ] Argo Rollouts canary deployments
- [ ] Chaos engineering with Litmus
- [ ] Velero backup and disaster recovery
- [ ] Terraform remote state backend (S3 + DynamoDB)
- [ ] Production environment Terraform config

---

## Local development tips

```bash
# Rebuild a single service without restarting everything
docker compose -f platform/local/compose.yaml up --build vote

# Watch logs for the worker
docker compose -f platform/local/compose.yaml logs -f worker

# Connect to PostgreSQL directly
docker compose -f platform/local/compose.yaml exec db \
  psql -U voting -d votes

# Check vote counts
docker compose -f platform/local/compose.yaml exec db \
  psql -U voting -d votes -c "SELECT vote, COUNT(*) FROM votes GROUP BY vote;"

# Run seed data to populate test votes
docker compose -f platform/local/compose.yaml --profile seed run --rm seed-data
```

---

## Requirements

| Tool | Version | Purpose |
|------|---------|---------|
| Docker | 24+ | Local dev + image builds |
| docker compose | v2 | Local orchestration |
| kubectl | 1.29+ | Cluster interaction |
| helm | 3.14+ | Chart install + templating |
| terraform | 1.7+ | Infrastructure provisioning |
| AWS CLI | 2.x | AWS interaction |

---

## Author

Built by **Ahmed** ([@BARDICY23](https://github.com/BARDICY23)) —
3rd year Information Systems student, AWS Certified (SAA + Cloud Practitioner),
CKA candidate.

This project was built to learn by doing — every component was chosen deliberately,
every tradeoff documented. If something looks wrong or could be better, open an issue.
