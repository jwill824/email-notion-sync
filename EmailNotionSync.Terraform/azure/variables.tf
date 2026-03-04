variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "East US 2"
}

variable "gmail_api_name" {
  description = "Name of the GmailApi Container App"
  type        = string
  default     = "gmail-api"
}

variable "gmail_api_image" {
  description = "Container image for GmailApi"
  type        = string
}

variable "notion_api_name" {
  description = "Name of the NotionApi Container App"
  type        = string
  default     = "notion-api"
}

variable "notion_api_image" {
  description = "Container image for NotionApi"
  type        = string
}

variable "gmail_api_key" {
  description = "Gmail API key secret value"
  type        = string
  sensitive   = true
}

variable "notion_api_key" {
  description = "Notion API key secret value"
  type        = string
  sensitive   = true
}

variable "hcp_sp_object_id" {
  description = "Object id (principal) of the Terraform/HCP service principal that needs Key Vault secret access. Provide via Terraform Cloud variable or CLI."
  type        = string
}

# ── Required GitHub Actions secrets ──────────────────────────────────────────
# The following variables document the GitHub Actions secrets and Terraform
# Cloud variables that must be configured before CI and Terraform apply can run.
#
#  GitHub Actions secrets (repo or org level):
#    AZURE_CLIENT_ID        — client ID of the OIDC-federated service principal
#    AZURE_TENANT_ID        — Azure AD tenant ID
#    AZURE_SUBSCRIPTION_ID  — Azure subscription ID
#    AZURE_RESOURCE_GROUP   — resource group name (used by deploy workflows)
#    AZURE_FUNCTIONAPP_NAME — function app name (used by deploy-function-app.yml)
#    HCP_SP_CLIENT_ID       — client ID of the HCP/Terraform provisioning SP
#                             (used by the provisioning pre-check workflow)
#
#  Terraform Cloud workspace variables (sensitive):
#    gmail_api_key          — mapped to var.gmail_api_key
#    notion_api_key         — mapped to var.notion_api_key
#    hcp_sp_object_id       — mapped to var.hcp_sp_object_id
#    gmail_api_image        — container image tag for GmailApi
#    notion_api_image       — container image tag for NotionApi
#    github_owner           — GitHub owner (e.g. "myorg")
#    github_repo            — GitHub repo name (e.g. "email-notion-sync")
# ─────────────────────────────────────────────────────────────────────────────

variable "github_owner" {
  description = "GitHub owner or organization where the container images are hosted"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name where the container images are hosted"
  type        = string
}
