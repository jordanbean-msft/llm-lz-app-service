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
# Deploy cognitive services
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "cognitiveservices_name" {
  name          = "openai-${var.resource_token}"
  resource_type = "azurerm_cognitive_account"
  random_length = 0
  clean_input   = true
}

resource "azurerm_cognitive_account" "cognitive_account" {
  name                          = azurecaf_name.cognitiveservices_name.result
  location                      = var.location
  resource_group_name           = var.resource_group_name
  kind                          = "OpenAI"
  sku_name                      = var.sku_name
  custom_subdomain_name         = azurecaf_name.cognitiveservices_name.result
  public_network_access_enabled = false
}

resource "azurerm_cognitive_deployment" "cognitive_deployment" {
  for_each = {
    for combination in flatten([
      for model in var.openai_model_deployments : {
        model_format    = model.model.format
        model_name      = model.model.name
        model_version   = model.model.version
        sku_name        = model.sku.name
        sku_capacity    = model.sku.capacity
        rai_policy_name = model.rai_policy_name
      }
    ]) : "${combination.model_name}" => combination
  }
  name                 = "${each.value.model_name}-${each.value.model_version}"
  cognitive_account_id = azurerm_cognitive_account.cognitive_account.id
  model {
    format  = each.value.model_format
    name    = each.value.model_name
    version = each.value.model_version
  }
  sku {
    name     = each.value.sku_name
    capacity = each.value.sku_capacity
  }
  rai_policy_name = each.value.rai_policy_name
}

module "private_endpoint" {
  source                         = "../private_endpoint"
  name                           = azurerm_cognitive_account.cognitive_account.name
  resource_group_name            = var.resource_group_name
  tags                           = var.tags
  resource_token                 = var.resource_token
  private_connection_resource_id = azurerm_cognitive_account.cognitive_account.id
  location                       = var.location
  subnet_id                      = var.subnet_id
  subresource_names              = ["account"]
  is_manual_connection           = false
}

resource "azurerm_monitor_diagnostic_setting" "openai_logging" {
  name                       = "openai-logging"
  target_resource_id         = azurerm_cognitive_account.cognitive_account.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "RequestResponse"
  }

  metric {
    category = "AllMetrics"
  }
}