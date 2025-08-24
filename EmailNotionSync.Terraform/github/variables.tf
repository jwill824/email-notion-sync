variable "github_token" {
  description = "GitHub personal access token with repo and workflow permissions"
  type        = string
  sensitive   = true
}

variable "github_owner" {
  description = "GitHub organization or user name"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
}

variable "function_app_name" {
  description = "Name of the Azure Function App"
  type        = string
}

variable "azure_gmailapi_app_name" {
  description = "Azure GmailApi Container App name"
  type        = string
}

variable "azure_notionapi_app_name" {
  description = "Azure NotionApi Container App name"
  type        = string
}

variable "azure_resource_group" {
  description = "Azure Resource Group name"
  type        = string
}

variable "azure_client_id" {
  description = "Azure AD App (client) ID for OIDC federation"
  type        = string
}

variable "azure_tenant_id" {
  description = "Azure tenant ID"
  type        = string
}

variable "azure_subscription_id" {
  description = "Azure subscription ID"
  type        = string
}
