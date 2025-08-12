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
