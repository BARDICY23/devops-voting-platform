output "region" {
  value = var.region
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "private_subnet_ids" {
  value = module.vpc.private_subnets
}

output "public_subnet_ids" {
  value = module.vpc.public_subnets
}

output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "oidc_provider_arn" {
  value = module.eks.oidc_provider_arn
}

output "alb_controller_irsa_role_arn" {
  value = module.iam_assumable_role_alb_controller.iam_role_arn
}

output "external_secrets_irsa_role_arn" {
  value = module.iam_assumable_role_external_secrets.iam_role_arn
}

output "secrets_manager_postgres_secret_name" {
  value       = try(aws_secretsmanager_secret.postgres_password[0].name, null)
  description = "Only set if create_secrets_manager_secrets=true"
}

output "secrets_manager_redis_secret_name" {
  value       = try(aws_secretsmanager_secret.redis_password[0].name, null)
  description = "Only set if create_secrets_manager_secrets=true"
}
