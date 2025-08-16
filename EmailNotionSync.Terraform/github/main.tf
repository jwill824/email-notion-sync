terraform {
  required_version = ">= 1.5.0"
  required_providers {
    github = {
      source  = "integrations/github"
      version = ">= 5.0.0"
    }
  }
  cloud {
    organization = "Thingstead"
    workspaces {
      name = "email-notion-sync-github"
    }
  }
}

provider "github" {
  token = var.github_token
  owner = var.github_owner
}

resource "github_actions_secret" "azure_functionapp_name" {
  repository      = var.github_repo
  secret_name     = "AZURE_FUNCTIONAPP_NAME"
  plaintext_value = var.function_app_name
}

resource "github_actions_secret" "azure_functionapp_publish_profile" {
  repository      = var.github_repo
  secret_name     = "AZURE_FUNCTIONAPP_PUBLISH_PROFILE"
  plaintext_value = var.azure_functionapp_publish_profile
}
