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

resource "github_actions_secret" "azure_credentials" {
  repository      = var.github_repo
  secret_name     = "AZURE_CREDENTIALS"
  plaintext_value = var.azure_credentials
}

resource "github_actions_secret" "azure_gmailapi_app_name" {
  repository      = var.github_repo
  secret_name     = "AZURE_GMAILAPI_APP_NAME"
  plaintext_value = var.azure_gmailapi_app_name
}

resource "github_actions_secret" "azure_notionapi_app_name" {
  repository      = var.github_repo
  secret_name     = "AZURE_NOTIONAPI_APP_NAME"
  plaintext_value = var.azure_notionapi_app_name
}

resource "github_actions_secret" "azure_resource_group" {
  repository      = var.github_repo
  secret_name     = "AZURE_RESOURCE_GROUP"
  plaintext_value = var.azure_resource_group
}
