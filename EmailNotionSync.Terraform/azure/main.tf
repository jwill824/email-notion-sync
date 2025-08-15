terraform {
  required_version = ">= 1.5.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 3.75.0"
    }
  }
  cloud {
    organization = "Thingstead"
    workspaces {
      name = "email-notion-sync-azure"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "main" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "main" {
  name                     = "${var.function_app_name}sa"
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_service_plan" "main" {
  name                = "${var.function_app_name}-plan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Y1"
  os_type             = "Linux"
}

resource "azurerm_linux_function_app" "main" {
  name                       = var.function_app_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  service_plan_id            = azurerm_service_plan.main.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  identity {
    type = "SystemAssigned"
  }
  site_config {
    application_stack {
      dotnet_version = "6.0"
    }
  }
  app_settings = {
    FUNCTIONS_WORKER_RUNTIME = "dotnet"
    AzureWebJobsStorage      = azurerm_storage_account.main.primary_connection_string
  }
}

resource "azurerm_key_vault" "main" {
  name                     = var.key_vault_name
  location                 = azurerm_resource_group.main.location
  resource_group_name      = azurerm_resource_group.main.name
  tenant_id                = data.azurerm_client_config.current.tenant_id
  sku_name                 = "standard"
  purge_protection_enabled = true
  access_policy {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    object_id          = azurerm_linux_function_app.main.identity[0].principal_id
    secret_permissions = ["get", "list"]
  }
}

data "azurerm_client_config" "current" {}

resource "azurerm_container_app_environment" "main" {
  name                = "${var.project_name}-cae"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_container_app" "gmailapi" {
  name                         = var.gmail_api_name
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  identity {
    type = "SystemAssigned"
  }
  ingress {
    external_enabled = true
    target_port      = 8080
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  template {
    container {
      name   = "gmailapi"
      image  = var.gmail_api_image
      cpu    = 0.5
      memory = "1Gi"
      env {
        name  = "ASPNETCORE_ENVIRONMENT"
        value = "Production"
      }
    }
  }
}

resource "azurerm_container_app" "notionapi" {
  name                         = var.notion_api_name
  container_app_environment_id = azurerm_container_app_environment.main.id
  resource_group_name          = azurerm_resource_group.main.name
  revision_mode                = "Single"
  identity {
    type = "SystemAssigned"
  }
  ingress {
    external_enabled = true
    target_port      = 8080
    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }
  template {
    container {
      name   = "notionapi"
      image  = var.notion_api_image
      cpu    = 0.5
      memory = "1Gi"
      env {
        name  = "ASPNETCORE_ENVIRONMENT"
        value = "Production"
      }
    }
  }
}

resource "azurerm_key_vault_access_policy" "gmailapi" {
  key_vault_id       = azurerm_key_vault.main.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = azurerm_container_app.gmailapi.identity[0].principal_id
  secret_permissions = ["Get", "List"]
}

resource "azurerm_key_vault_access_policy" "notionapi" {
  key_vault_id       = azurerm_key_vault.main.id
  tenant_id          = data.azurerm_client_config.current.tenant_id
  object_id          = azurerm_container_app.notionapi.identity[0].principal_id
  secret_permissions = ["Get", "List"]
}

resource "azurerm_application_insights" "main" {
  name                = var.app_insights_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  application_type    = "web"
}

resource "azurerm_key_vault_secret" "gmail_api_key" {
  name         = "GmailApiKey"
  value        = var.gmail_api_key
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_key_vault_secret" "notion_api_key" {
  name         = "NotionApiKey"
  value        = var.notion_api_key
  key_vault_id = azurerm_key_vault.main.id
}
