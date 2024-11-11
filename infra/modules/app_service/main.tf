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
  }
}
# ------------------------------------------------------------------------------------------------------
# Deploy App Service Plan
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "app_service_plan_name" {
  name          = var.resource_token
  resource_type = "azurerm_app_service_plan"
  random_length = 0
  clean_input   = true
}

resource "azurerm_service_plan" "app_service_plan" {
  name                = azurecaf_name.app_service_plan_name.result
  location            = var.location
  resource_group_name = var.resource_group_name
  os_type             = "Linux"
  sku_name            = var.sku_name
}

# ------------------------------------------------------------------------------------------------------
# Deploy App Service
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "app_service_name" {
  name          = var.resource_token
  resource_type = "azurerm_linux_web_app"
  random_length = 0
  clean_input   = true
}

resource "azurerm_linux_web_app" "app_service" {
  name                      = azurecaf_name.app_service_name.result
  location                  = var.location
  resource_group_name       = var.resource_group_name
  service_plan_id           = azurerm_service_plan.app_service_plan.id
  virtual_network_subnet_id = var.subnet_id
  identity {
    type         = "UserAssigned"
    identity_ids = [var.managed_identity_id]
  }
  key_vault_reference_identity_id = var.managed_identity_id
  app_settings = {

  }
  site_config {
  }
}

module "private_endpoint" {
  source                         = "../private_endpoint"
  name                           = azurerm_linux_web_app.app_service.name
  resource_group_name            = var.resource_group_name
  tags                           = var.tags
  resource_token                 = var.resource_token
  private_connection_resource_id = azurerm_linux_web_app.app_service.id
  location                       = var.location
  subnet_id                      = var.private_endpoint_subnet_id
  subresource_names              = ["sites"]
  is_manual_connection           = false
}