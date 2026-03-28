terraform {
  required_version = ">= 1.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.region

  # OIDC authentication via GitHub Actions:
  # AWS_ROLE_ARN and AWS_REGION are set from environment secrets.
  # Locally, run: aws configure (or use AWS_PROFILE env var)
}
