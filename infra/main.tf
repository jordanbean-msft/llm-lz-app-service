locals {
  tags           = { azd-env-name : var.environment_name }
  sha            = base64encode(sha256("${var.location}${data.azurerm_client_config.current.subscription_id}${var.resource_group_name}"))
  resource_token = substr(replace(lower(local.sha), "[^A-Za-z0-9_]", ""), 0, 13)
  #app_subnet_nsg_name              = "nsg-${var.network.apim_subnet_name}-subnet"
  #private_endpoint_subnet_nsg_name = "nsg-${var.network.private_endpoint_subnet_name}-subnet"
  azure_openai_secret_name                                   = "azure-openai-key"
  azure_cognitive_services_secret_name                       = "azure-cognitive-services-key"
  azure_search_service_secret_name                           = "azure-search-service-key"
  document_storage_account_connection_string_secret_name     = "document-storage-account-connection-string"
  function_app_storage_account_connection_string_secret_name = "function-app-storage-account-connection-string"
  cosmosdb_account_key_secret_name                           = "cosmosdb-account-key"
  function_app_resource_token                                = "func-${local.resource_token}"
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
  subscription_id              = data.azurerm_client_config.current.subscription_id
  subnets                      = []
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
    },
    {
      name  = local.document_storage_account_connection_string_secret_name
      value = module.document_storage_account.storage_account_connection_string
    },
    {
      name  = local.cosmosdb_account_key_secret_name
      value = module.cosmosdb.cosmosdb_account_key
    },
    {
      name  = local.function_app_storage_account_connection_string_secret_name
      value = module.function_app_storage_account.storage_account_connection_string
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
  chat_model_name                  = var.openai.chat_model_name
  embeddings_model_name            = var.openai.embeddings_model_name
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
  zone_balancing_enabled                 = var.app_service.zone_balancing_enabled
  app_settings = {
    "AZURE_OPENAI_ENDPOINT"                 = module.openai.azure_cognitive_services_endpoint
    "AZURE_OPENAI_KEY"                      = "@Microsoft.KeyVault(VaultName=${module.key_vault.key_vault_name};SecretName=${local.azure_openai_secret_name})"
    "AZURE_DOC_INTEL_ENDPOINT"              = module.document_intelligence.azure_cognitive_services_endpoint
    "AZURE_COGNITIVE_SERVICES_KEY"          = "@Microsoft.KeyVault(VaultName=${module.key_vault.key_vault_name};SecretName=${local.azure_cognitive_services_secret_name})"
    "AZURE_SEARCH_ENDPOINT"                 = module.search_service.azure_search_service_endpoint
    "AZURE_SEARCH_SERVICE_KEY"              = "@Microsoft.KeyVault(VaultName=${module.key_vault.key_vault_name};SecretName=${local.azure_search_service_secret_name})"
    "APPINSIGHTS_INSTRUMENTATIONKEY"        = module.application_insights.application_insights_instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING" = module.application_insights.application_insights_connection_string
  }
  log_analytics_workspace_id = module.log_analytics.log_analytics_workspace_id
}

# ------------------------------------------------------------------------------------------------------
# Deploy Function App
# ------------------------------------------------------------------------------------------------------

module "function_app" {
  source                                 = "./modules/function_app"
  location                               = var.location
  resource_group_name                    = var.resource_group_name
  tags                                   = local.tags
  resource_token                         = local.function_app_resource_token
  managed_identity_id                    = module.managed_identity.user_assigned_identity_id
  subnet_id                              = module.virtual_network.function_app_subnet_id
  private_endpoint_subnet_id             = module.virtual_network.private_endpoint_subnet_id
  sku_name                               = var.function_app.sku_name
  storage_account_name                   = module.function_app_storage_account.storage_account_name
  application_insights_connection_string = module.application_insights.application_insights_connection_string
  application_insights_key               = module.application_insights.application_insights_instrumentation_key
  zone_balancing_enabled                 = var.function_app.zone_balancing_enabled
  app_settings = {
    "AOAI_KEY"                                 = "@Microsoft.KeyVault(VaultName=${module.key_vault.key_vault_name};SecretName=${local.azure_openai_secret_name})"
    "AOAI_ENDPOINT"                            = module.openai.azure_cognitive_services_endpoint
    "AOAI_EMBEDDINGS_MODEL"                    = module.openai.embeddings_model_name
    "AOAI_EMBEDDINGS_DIMENSIONS"               = 1536
    "AOAI_GPT_VISION_MODEL"                    = module.openai.chat_model_name
    "DOC_INTEL_ENDPOINT"                       = module.document_intelligence.azure_cognitive_services_endpoint
    "DOC_INTEL_KEY"                            = "@Microsoft.KeyVault(VaultName=${module.key_vault.key_vault_name};SecretName=${local.azure_cognitive_services_secret_name})"
    "SEARCH_ENDPOINT"                          = module.search_service.azure_search_service_endpoint
    "SEARCH_KEY"                               = "@Microsoft.KeyVault(VaultName=${module.key_vault.key_vault_name};SecretName=${local.azure_search_service_secret_name})"
    "SEARCH_SERVICE_NAME"                      = module.search_service.azure_search_service_name,
    "STORAGE_CONN_STR"                         = "@Microsoft.KeyVault(VaultName=${module.key_vault.key_vault_name};SecretName=${local.document_storage_account_connection_string_secret_name})"
    "COSMOS_ENDPOINT"                          = module.cosmosdb.cosmosdb_account_endpoint
    "COSMOS_KEY"                               = "@Microsoft.KeyVault(VaultName=${module.key_vault.key_vault_name};SecretName=${local.cosmosdb_account_key_secret_name})"
    "COSMOS_DATABASE"                          = module.cosmosdb.cosmosdb_sql_database_name
    "COSMOS_CONTAINER"                         = module.cosmosdb.ingestion_cosmosdb_sql_container_name
    "COSMOS_PROFILE_CONTAINER"                 = module.cosmosdb.ingestion_profile_cosmosdb_sql_container_name,
    "WEBSITE_CONTENTOVERVNET"                  = 1
    "WEBSITE_CONTENTAZUREFILECONNECTIONSTRING" = module.function_app_storage_account.storage_account_connection_string #this is a workaround for the issue with the function app not being able to access the storage account
    "WEBSITE_CONTENTSHARE"                     = azurerm_storage_share.function_app_file_share.name
    "APPINSIGHTS_INSTRUMENTATIONKEY"           = module.application_insights.application_insights_instrumentation_key
    "APPLICATIONINSIGHTS_CONNECTION_STRING"    = module.application_insights.application_insights_connection_string
  }
  log_analytics_workspace_id = module.log_analytics.log_analytics_workspace_id
}

resource "azurerm_storage_share" "function_app_file_share" {
  name                 = "func-${local.resource_token}"
  storage_account_name = module.function_app_storage_account.storage_account_name
  quota                = 50
}

resource "azurerm_storage_container" "content_container" {
  name                  = "content"
  storage_account_name  = module.document_storage_account.storage_account_name
  container_access_type = "private"
}

# ------------------------------------------------------------------------------------------------------
# Deploy Container Registry
# ------------------------------------------------------------------------------------------------------

module "container_registry" {
  source                        = "./modules/container_registry"
  location                      = var.location
  resource_group_name           = var.resource_group_name
  tags                          = local.tags
  resource_token                = local.resource_token
  subnet_id                     = module.virtual_network.private_endpoint_subnet_id
  managed_identity_principal_id = module.managed_identity.user_assigned_identity_principal_id
}

# ------------------------------------------------------------------------------------------------------
# Deploy CosmosDB
# ------------------------------------------------------------------------------------------------------
module "cosmosdb" {
  source                              = "./modules/cosmosdb"
  location                            = var.location
  resource_group_name                 = var.resource_group_name
  resource_token                      = local.resource_token
  tags                                = local.tags
  subnet_id                           = module.virtual_network.private_endpoint_subnet_id
  user_assigned_identity_principal_id = module.managed_identity.user_assigned_identity_principal_id
  subscription_id                     = data.azurerm_client_config.current.subscription_id
  principal_id                        = var.principal_id
  document_time_to_live               = var.cosmos_db.document_time_to_live
  max_throughput                      = var.cosmos_db.max_throughput
  zone_redundant                      = var.cosmos_db.zone_redundant
}