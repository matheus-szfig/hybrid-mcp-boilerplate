terraform {
  required_version = ">= 1.6"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.117"
    }
  }
}

provider "azurerm" {
  subscription_id = var.subscription_id

  # OIDC authentication — no client secrets required.
  # In GitHub Actions, ARM_CLIENT_ID / ARM_TENANT_ID are set from environment secrets.
  # Locally, run: az login
  features {}
}
