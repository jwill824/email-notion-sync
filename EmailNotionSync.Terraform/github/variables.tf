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

variable "azure_functionapp_publish_profile" {
  description = "Azure Function App publish profile XML string"
  type        = string
  sensitive   = true
}
