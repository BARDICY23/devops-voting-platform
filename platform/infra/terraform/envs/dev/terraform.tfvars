# Example dev values. Adjust as needed.
region             = "eu-west-1"
name               = "voting-dev"
kubernetes_version = "1.31"
az_count           = 2

# Cost optimization: single NAT gateway for dev to save ~$32/month.
# In production, set single_nat_gateway = false for one NAT per AZ (high availability).
# single_nat_gateway = true

# node_instance_types = ["t3.medium"]
# node_min_size       = 2
# node_max_size       = 4
# node_desired_size   = 2

# create_secrets_manager_secrets = false
