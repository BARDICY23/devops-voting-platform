locals {
  # Pick N AZs in region
  azs = slice(data.aws_availability_zones.available.names, 0, var.az_count)

  # Derive subnets deterministically
  # /16 -> create /20s; split into public/private per AZ
  public_subnets  = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i)]
  private_subnets = [for i, az in local.azs : cidrsubnet(var.vpc_cidr, 4, i + 8)]
}

data "aws_availability_zones" "available" {
  state = "available"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = var.name
  cidr = var.vpc_cidr

  azs             = local.azs
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets

  # Required for AWS Load Balancer Controller (ALB/NLB) subnet discovery
  public_subnet_tags = {
    "kubernetes.io/cluster/${var.name}" = "shared"
    "kubernetes.io/role/elb"           = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.name}" = "shared"
    "kubernetes.io/role/internal-elb"   = 1
  }

  enable_nat_gateway = true
  # Cost optimization: single NAT for dev (~$32/month saved).
  # For production, set to false to deploy one NAT per AZ for high availability.
  single_nat_gateway = true

  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Project = var.name
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.name
  cluster_version = var.kubernetes_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access  = true
  cluster_endpoint_private_access = true

  enable_irsa = true

  eks_managed_node_groups = {
    default = {
      name            = "${var.name}-ng"
      instance_types  = var.node_instance_types
      min_size        = var.node_min_size
      max_size        = var.node_max_size
      desired_size    = var.node_desired_size

      subnet_ids = module.vpc.private_subnets

      labels = {
        workload = "general"
      }

      tags = {
        Project = var.name
      }
    }
  }

  tags = {
    Project = var.name
  }
}

#
# IRSA roles for in-cluster controllers
#

# AWS Load Balancer Controller policy (baseline). Update if AWS publishes changes.
data "aws_iam_policy_document" "alb_controller" {
  statement {
    sid    = "ALBControllerCore"
    effect = "Allow"
    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:GetCertificate",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcPeeringConnections",
      "ec2:DescribeSubnets",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeInstances",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeTags",
      "ec2:DescribeCoipPools",
      "ec2:GetCoipPoolUsage",
      "ec2:DescribeLaunchTemplates",
      "ec2:DescribeRouteTables",
      "ec2:DescribeInstanceStatus",
      "ec2:RevokeSecurityGroupIngress",
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:SetWebAcl",
      "iam:CreateServiceLinkedRole",
      "iam:GetServerCertificate",
      "iam:ListServerCertificates",
      "cognito-idp:DescribeUserPoolClient",
      "waf-regional:GetWebACLForResource",
      "waf-regional:GetWebACL",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
      "wafv2:GetWebACLForResource",
      "wafv2:GetWebACL",
      "wafv2:AssociateWebACL",
      "wafv2:DisassociateWebACL",
      "shield:GetSubscriptionState",
      "shield:DescribeProtection",
      "shield:CreateProtection",
      "shield:DeleteProtection",
      "ec2:DescribeManagedPrefixLists",
      "ec2:GetManagedPrefixListEntries",
      "ec2:ModifyManagedPrefixList",
      "ec2:DescribeNetworkAcls",
      "ec2:DescribeSecurityGroupRules",
      "ec2:CreateSecurityGroupRule",
      "ec2:DeleteSecurityGroupRule"
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "alb_controller" {
  name   = "${var.name}-alb-controller"
  policy = data.aws_iam_policy_document.alb_controller.json
}

module "iam_assumable_role_alb_controller" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.name}-alb-controller-irsa"

  role_policy_arns = {
    alb_controller = aws_iam_policy.alb_controller.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
    }
  }

  tags = {
    Project = var.name
  }
}

# External Secrets Operator - read-only access to Secrets Manager
# Scoped to only this project's secret path prefix (least-privilege).
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "external_secrets" {
  statement {
    sid    = "ESOGetSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]
    resources = [
      "arn:aws:secretsmanager:${var.region}:${data.aws_caller_identity.current.account_id}:secret:${var.name}/*"
    ]
  }

  statement {
    sid    = "ESOListSecrets"
    effect = "Allow"
    actions = [
      "secretsmanager:ListSecrets",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "external_secrets" {
  name   = "${var.name}-external-secrets"
  policy = data.aws_iam_policy_document.external_secrets.json
}

module "iam_assumable_role_external_secrets" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.0"

  role_name = "${var.name}-external-secrets-irsa"

  role_policy_arns = {
    external_secrets = aws_iam_policy.external_secrets.arn
  }

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["external-secrets:external-secrets"]
    }
  }

  tags = {
    Project = var.name
  }
}

#
# Optional: create placeholder Secrets Manager secrets (disabled by default)
#
resource "aws_secretsmanager_secret" "postgres_password" {
  count = var.create_secrets_manager_secrets ? 1 : 0
  name  = "${var.name}/postgres/password"
  tags = { Project = var.name }
}

resource "aws_secretsmanager_secret" "redis_password" {
  count = var.create_secrets_manager_secrets ? 1 : 0
  name  = "${var.name}/redis/password"
  tags = { Project = var.name }
}

resource "random_password" "postgres" {
  count            = var.create_secrets_manager_secrets ? 1 : 0
  length           = 24
  special          = true
  override_special = "!@#%^*-_=+"
}

resource "random_password" "redis" {
  count            = var.create_secrets_manager_secrets ? 1 : 0
  length           = 24
  special          = true
  override_special = "!@#%^*-_=+"
}

resource "aws_secretsmanager_secret_version" "postgres_password" {
  count         = var.create_secrets_manager_secrets ? 1 : 0
  secret_id     = aws_secretsmanager_secret.postgres_password[0].id
  secret_string = random_password.postgres[0].result
}

resource "aws_secretsmanager_secret_version" "redis_password" {
  count         = var.create_secrets_manager_secrets ? 1 : 0
  secret_id     = aws_secretsmanager_secret.redis_password[0].id
  secret_string = random_password.redis[0].result
}
