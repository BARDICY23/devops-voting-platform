provider "aws" {
  region = var.region
}

# Optional: enable if you want to use the kubernetes/helm providers from Terraform.
# In this project we keep Helm installs in the platform layer (GitOps/Helm), not Terraform.
#
# data "aws_eks_cluster" "this" {
#   name = module.eks.cluster_name
# }
#
# data "aws_eks_cluster_auth" "this" {
#   name = module.eks.cluster_name
# }
#
# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.this.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.this.certificate_authority[0].data)
#   token                  = data.aws_eks_cluster_auth.this.token
# }
