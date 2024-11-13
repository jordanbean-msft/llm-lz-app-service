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
# DEPLOY APPLICATION INSIGHTS
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "application_insights_name" {
  name          = var.resource_token
  resource_type = "azurerm_application_insights"
  random_length = 0
  clean_input   = true
}

resource "azurerm_application_insights" "applicationinsights" {
  name                       = azurecaf_name.application_insights_name.result
  location                   = var.location
  resource_group_name        = var.resource_group_name
  application_type           = "other"
  workspace_id               = var.workspace_id
  tags                       = var.tags
  internet_ingestion_enabled = true
  internet_query_enabled     = true
}
