terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75.0"
    }
  }
  cloud {
    organization = "Thingstead"
    workspaces {
      name = "email-notion-sync"
    }
  }
}

provider "azurerm" {
  features {}
}
