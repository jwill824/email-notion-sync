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

resource "azurerm_app_service_plan" "main" {
  name                = "${var.function_app_name}-plan"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  kind                = "FunctionApp"
  reserved            = true
  sku {
    tier = "Dynamic"
    size = "Y1"
  }
}

resource "azurerm_function_app" "main" {
  name                       = var.function_app_name
  location                   = azurerm_resource_group.main.location
  resource_group_name        = azurerm_resource_group.main.name
  app_service_plan_id        = azurerm_app_service_plan.main.id
  storage_account_name       = azurerm_storage_account.main.name
  storage_account_access_key = azurerm_storage_account.main.primary_access_key
  os_type                    = "linux"
  version                    = "~4"
  identity {
    type = "SystemAssigned"
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
  # soft_delete_enabled is not supported in recent azurerm provider versions (always enabled)
  access_policy {
    tenant_id          = data.azurerm_client_config.current.tenant_id
    object_id          = azurerm_function_app.main.identity[0].principal_id
    secret_permissions = ["get", "list"]
  }
}

data "azurerm_client_config" "current" {}
