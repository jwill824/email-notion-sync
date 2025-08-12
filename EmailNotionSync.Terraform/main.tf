terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.0.0"
    }
  }
  cloud {
    organization = "YOUR_TERRAFORM_CLOUD_ORG"
    workspaces {
      name = "email-notion-sync"
    }
  }
}

provider "azurerm" {
  features {}
}
