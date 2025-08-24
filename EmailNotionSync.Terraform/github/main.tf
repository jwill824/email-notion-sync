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

resource "github_actions_secret" "azure_client_id" {
  repository      = var.github_repo
  secret_name     = "AZURE_CLIENT_ID"
  plaintext_value = var.azure_client_id
}

resource "github_actions_secret" "azure_tenant_id" {
  repository      = var.github_repo
  secret_name     = "AZURE_TENANT_ID"
  plaintext_value = var.azure_tenant_id
}

resource "github_actions_secret" "azure_subscription_id" {
  repository      = var.github_repo
  secret_name     = "AZURE_SUBSCRIPTION_ID"
  plaintext_value = var.azure_subscription_id
}
