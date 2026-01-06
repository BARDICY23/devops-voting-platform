# Terraform (AWS) – EKS + VPC + IRSA (ALB Controller + External Secrets)

This Terraform stack provisions the **AWS primitives** for the project:

- VPC (public + private subnets across AZs)
- EKS cluster (managed control plane)
- Managed node group (EC2 workers)
- IRSA (IAM Roles for Service Accounts) for:
  - **AWS Load Balancer Controller** (ALB Ingress)
  - **External Secrets Operator** (AWS Secrets Manager)

**What this does NOT provision**
- The ALB itself (created dynamically by Kubernetes via Ingress + AWS Load Balancer Controller)
- DNS records (you will point GoDaddy records to the ALB DNS name later)
- Helm installs (Argo CD / Helm handles in-cluster add-ons and apps)

## Usage (dev)

From `infra/terraform/envs/dev`:

```bash
terraform init
terraform plan
terraform apply
```

Then configure kubectl:

```bash
aws eks update-kubeconfig --region <region> --name <cluster_name>
```

## Next (after apply)

1. Install **AWS Load Balancer Controller** via Helm using the IRSA role ARN output:
   - `alb_controller_irsa_role_arn`

2. Install **External Secrets Operator** via Helm using:
   - `external_secrets_irsa_role_arn`

3. Create an **Ingress** with ALB annotations (in your app Helm chart) to create an ALB.

## Notes

- This stack uses `terraform-aws-modules/vpc/aws`, `terraform-aws-modules/eks/aws`,
  and `terraform-aws-modules/iam/aws` for reliable defaults.
- If you need to pin Kubernetes version, set `kubernetes_version`.
