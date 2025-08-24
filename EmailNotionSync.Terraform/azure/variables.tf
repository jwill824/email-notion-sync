variable "location" {
  description = "Azure region to deploy resources"
  type        = string
  default     = "East US"
}

variable "project_name" {
  description = "Project name prefix for resources"
  type        = string
  default     = "email-notion-sync"
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
