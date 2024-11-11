terraform {
  required_providers {
    azurerm = {
      version = "4.9.0"
      source  = "hashicorp/azurerm"
    }
    azurecaf = {
      source  = "aztfmod/azurecaf"
      version = "1.2.28"
    }
    azapi = {
      source  = "Azure/azapi"
      version = "2.0.1"
    }
  }
}
# ------------------------------------------------------------------------------------------------------
# Deploy App Service Plan
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "function_app_plan_name" {
  name          = var.resource_token
  resource_type = "azurerm_app_service_plan"
  random_length = 0
  clean_input   = true
}

resource "azurerm_service_plan" "function_app_plan" {
  name                   = azurecaf_name.function_app_plan_name.result
  location               = var.location
  resource_group_name    = var.resource_group_name
  os_type                = "Linux"
  sku_name               = var.sku_name
  zone_balancing_enabled = var.zone_balancing_enabled
}

# ------------------------------------------------------------------------------------------------------
# Deploy Function App
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "function_app_name" {
  name          = var.resource_token
  resource_type = "azurerm_function_app"
  random_length = 0
  clean_input   = true
}

resource "azurerm_linux_function_app" "function_app" {
  name                            = azurecaf_name.function_app_name.result
  location                        = var.location
  resource_group_name             = var.resource_group_name
  service_plan_id                 = azurerm_service_plan.function_app_plan.id
  virtual_network_subnet_id       = var.subnet_id
  storage_account_name            = var.storage_account_name
  storage_uses_managed_identity   = true
  key_vault_reference_identity_id = var.managed_identity_id
  public_network_access_enabled   = false
  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity_id]
  }
  app_settings = var.app_settings
  https_only   = true
  site_config {
    application_insights_connection_string = var.application_insights_connection_string
    application_insights_key               = var.application_insights_key
    application_stack {
      python_version = "3.11"
    }
    ip_restriction_default_action    = "Deny"
    runtime_scale_monitoring_enabled = true
    ftps_state                       = "FtpsOnly"
  }
  depends_on = [
    azurerm_storage_share.function_app_share
  ]
}

resource "azapi_update_resource" "vnet_content_share_enabled" {
  type        = "Microsoft.Web/sites@2022-09-01"
  resource_id = azurerm_linux_function_app.function_app.id

  body = {
    properties = {
      vnetContentShareEnabled = true
    }
  }

  depends_on = [
    azurerm_linux_function_app.function_app
  ]
}

module "private_endpoint" {
  source                         = "../private_endpoint"
  name                           = azurerm_linux_function_app.function_app.name
  resource_group_name            = var.resource_group_name
  tags                           = var.tags
  resource_token                 = var.resource_token
  private_connection_resource_id = azurerm_linux_function_app.function_app.id
  location                       = var.location
  subnet_id                      = var.private_endpoint_subnet_id
  subresource_names              = ["sites"]
  is_manual_connection           = false
}

resource "azurerm_storage_share" "function_app_share" {
  name                 = azurecaf_name.function_app_name.result
  storage_account_name = var.storage_account_name
  quota                = 50
}

resource "azurerm_monitor_diagnostic_setting" "function_logging" {
  name                       = "function-logging"
  target_resource_id         = azurerm_linux_function_app.function_app.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "FunctionAppLogs"
  }

  metric {
    category = "AllMetrics"
  }
}