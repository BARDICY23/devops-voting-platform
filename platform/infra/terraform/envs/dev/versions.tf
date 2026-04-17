terraform {
  required_version = ">= 1.6.0"

  backend "s3" {
    bucket         = "devops-voting-platform-tfstate"
    key            = "envs/dev/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}
