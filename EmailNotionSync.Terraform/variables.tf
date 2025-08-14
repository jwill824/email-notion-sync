# Variables for Azure Function App and Key Vault
variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "East US"
}

variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
  default     = "email-notion-sync-rg"
}

variable "function_app_name" {
  description = "Name of the Azure Function App"
  type        = string
  default     = "emailnotionsyncfunc"
}

variable "key_vault_name" {
  description = "Name of the Azure Key Vault"
  type        = string
  default     = "emailnotionsynckv"
}

# Container Apps variables
variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default     = "emailnotionsync"
}

variable "gmail_api_name" {
  description = "Name of the GmailApi Container App"
  type        = string
  default     = "gmailapi"
}

variable "gmail_api_image" {
  description = "Container image for GmailApi"
  type        = string
}

variable "notion_api_name" {
  description = "Name of the NotionApi Container App"
  type        = string
  default     = "notionapi"
}

variable "notion_api_image" {
  description = "Container image for NotionApi"
  type        = string
}
