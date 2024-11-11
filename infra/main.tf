locals {
  tags           = { azd-env-name : var.environment_name }
  sha            = base64encode(sha256("${var.location}${data.azurerm_client_config.current.subscription_id}${var.resource_group_name}"))
  resource_token = substr(replace(lower(local.sha), "[^A-Za-z0-9_]", ""), 0, 13)
  #app_subnet_nsg_name              = "nsg-${var.network.apim_subnet_name}-subnet"
  #private_endpoint_subnet_nsg_name = "nsg-${var.network.private_endpoint_subnet_name}-subnet"
  azure_openai_secret_name             = "azure-openai-key"
  azure_cognitive_services_secret_name = "azure-cognitive-services-key"
  azure_search_service_secret_name     = "azure-search-service-apikey"
}

# ------------------------------------------------------------------------------------------------------
# Deploy virtual network
# ------------------------------------------------------------------------------------------------------

module "virtual_network" {
  source                       = "./modules/virtual_network"
  location                     = var.location
  resource_group_name          = var.network.virtual_network_resource_group_name
  tags                         = local.tags
  resource_token               = local.resource_token
  virtual_network_name         = var.network.virtual_network_name
  private_endpoint_subnet_name = var.network.private_endpoint_subnet_name
  function_app_subnet_name     = var.network.function_app_subnet_name
  app_service_subnet_name      = var.network.app_service_subnet_name
}

# ------------------------------------------------------------------------------------------------------
# Deploy application insights
# ------------------------------------------------------------------------------------------------------
module "application_insights" {
  source              = "./modules/application_insights"
  location            = var.location
  resource_group_name = var.resource_group_name
  workspace_id        = module.log_analytics.log_analytics_workspace_id
  tags                = local.tags
  resource_token      = local.resource_token
}

# ------------------------------------------------------------------------------------------------------
# Deploy log analytics
# ------------------------------------------------------------------------------------------------------
module "log_analytics" {
  source              = "./modules/log_analytics"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags
  resource_token      = local.resource_token
}

# ------------------------------------------------------------------------------------------------------
# Deploy managed identity
# ------------------------------------------------------------------------------------------------------
module "managed_identity" {
  source              = "./modules/managed_identity"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = local.tags
  resource_token      = local.resource_token
}

# ------------------------------------------------------------------------------------------------------
# Deploy key vault
# ------------------------------------------------------------------------------------------------------
module "key_vault" {
  source              = "./modules/key_vault"
  location            = var.location
  principal_id        = var.principal_id
  resource_group_name = var.resource_group_name
  tags                = local.tags
  resource_token      = local.resource_token
  access_policy_object_ids = [
    module.managed_identity.user_assigned_identity_object_id
  ]
  secrets = [
    {
      name  = local.azure_openai_secret_name
      value = module.openai.azure_cognitive_services_key
    },
    {
      name  = local.azure_cognitive_services_secret_name
      value = module.document_intelligence.azure_cognitive_services_key
    },
    {
      name  = local.azure_search_service_secret_name
      value = module.search_service.azure_search_service_apikey
    }
  ]
  subnet_id = module.virtual_network.private_endpoint_subnet_id
}

# ------------------------------------------------------------------------------------------------------
# Deploy OpenAI
# ------------------------------------------------------------------------------------------------------
module "openai" {
  source                           = "./modules/open_ai"
  location                         = var.location
  resource_group_name              = var.resource_group_name
  resource_token                   = local.resource_token
  tags                             = local.tags
  subnet_id                        = module.virtual_network.private_endpoint_subnet_id
  user_assigned_identity_object_id = module.managed_identity.user_assigned_identity_object_id
  log_analytics_workspace_id       = module.log_analytics.log_analytics_workspace_id
  openai_model_deployments         = var.openai.model_deployments
  sku_name                         = var.openai.sku_name
}

# ------------------------------------------------------------------------------------------------------
# Deploy Document Storage Account
# ------------------------------------------------------------------------------------------------------

module "document_storage_account" {
  source                        = "./modules/storage_account"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tags                          = local.tags
  resource_token                = "doc-${local.resource_token}"
  subnet_id                     = module.virtual_network.private_endpoint_subnet_id
  account_tier                  = var.storage_account.tier
  account_replication_type      = var.storage_account.replication_type
  managed_identity_principal_id = module.managed_identity.user_assigned_identity_principal_id
}

# ------------------------------------------------------------------------------------------------------
# Deploy Function App Storage Account
# ------------------------------------------------------------------------------------------------------

module "function_app_storage_account" {
  source                        = "./modules/storage_account"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tags                          = local.tags
  resource_token                = "func-${local.resource_token}"
  subnet_id                     = module.virtual_network.private_endpoint_subnet_id
  account_tier                  = var.storage_account.tier
  account_replication_type      = var.storage_account.replication_type
  managed_identity_principal_id = module.managed_identity.user_assigned_identity_principal_id
}

# ------------------------------------------------------------------------------------------------------
# Deploy Document Intelligence
# ------------------------------------------------------------------------------------------------------

module "document_intelligence" {
  source                        = "./modules/document_intelligence"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tags                          = local.tags
  resource_token                = local.resource_token
  subnet_id                     = module.virtual_network.private_endpoint_subnet_id
  managed_identity_principal_id = module.managed_identity.user_assigned_identity_principal_id
  sku_name                      = var.document_intelligence.sku_name
}

# ------------------------------------------------------------------------------------------------------
# Deploy Search Service
# ------------------------------------------------------------------------------------------------------

module "search_service" {
  source                        = "./modules/search_service"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tags                          = local.tags
  resource_token                = local.resource_token
  subnet_id                     = module.virtual_network.private_endpoint_subnet_id
  managed_identity_principal_id = module.managed_identity.user_assigned_identity_principal_id
  sku                           = var.ai_search.sku
}

# ------------------------------------------------------------------------------------------------------
# Deploy App Service
# ------------------------------------------------------------------------------------------------------

module "app_service" {
  source                                 = "./modules/app_service"
  location                               = var.location
  resource_group_name                    = var.resource_group_name
  tags                                   = local.tags
  resource_token                         = "app-${local.resource_token}"
  managed_identity_id                    = module.managed_identity.user_assigned_identity_id
  subnet_id                              = module.virtual_network.app_service_subnet_id
  private_endpoint_subnet_id             = module.virtual_network.private_endpoint_subnet_id
  sku_name                               = var.app_service.sku_name
  application_insights_connection_string = module.application_insights.application_insights_connection_string
  application_insights_key               = module.application_insights.application_insights_instrumentation_key
}

# ------------------------------------------------------------------------------------------------------
# Deploy Function App
# ------------------------------------------------------------------------------------------------------

module "function_app" {
  source                                 = "./modules/function_app"
  location                               = var.location
  resource_group_name                    = var.resource_group_name
  tags                                   = local.tags
  resource_token                         = "func-${local.resource_token}"
  managed_identity_id                    = module.managed_identity.user_assigned_identity_id
  subnet_id                              = module.virtual_network.function_app_subnet_id
  private_endpoint_subnet_id             = module.virtual_network.private_endpoint_subnet_id
  sku_name                               = var.function_app.sku_name
  storage_account_name                   = module.function_app_storage_account.storage_account_name
  application_insights_connection_string = module.application_insights.application_insights_connection_string
  application_insights_key               = module.application_insights.application_insights_instrumentation_key
}