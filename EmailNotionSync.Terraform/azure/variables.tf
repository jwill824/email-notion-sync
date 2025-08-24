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

variable "github_owner" {
  description = "GitHub owner or organization where the container images are hosted"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name where the container images are hosted"
  type        = string
}
