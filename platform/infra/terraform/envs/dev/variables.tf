variable "region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "name" {
  description = "Name prefix for all resources"
  type        = string
  default     = "voting-dev"
}

variable "kubernetes_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.29"
}

variable "vpc_cidr" {
  description = "CIDR for VPC"
  type        = string
  default     = "10.20.0.0/16"
}

variable "az_count" {
  description = "How many AZs to use"
  type        = number
  default     = 2
}

variable "node_instance_types" {
  description = "EC2 instance types for EKS managed node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_min_size" {
  type    = number
  default = 2
}
variable "node_max_size" {
  type    = number
  default = 4
}
variable "node_desired_size" {
  type    = number
  default = 2
}

variable "create_secrets_manager_secrets" {
  description = "If true, create placeholder Secrets Manager secrets (values generated). Often you will create them manually via AWS CLI instead."
  type        = bool
  default     = false
}
