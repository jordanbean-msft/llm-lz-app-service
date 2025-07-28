# ------------------------------------------------------------------------------------------------------
# Deploy cognitive services
# ------------------------------------------------------------------------------------------------------
resource "azurecaf_name" "cognitiveservices_name" {
  name          = "openai-${var.resource_token}"
  resource_type = "azurerm_cognitive_account"
  random_length = 0
  clean_input   = true
}


data "azurerm_resource_group" "resource_group" {
  name = var.resource_group_name
}

resource "azapi_resource" "ai_foundry" {
  type                      = "Microsoft.CognitiveServices/accounts@2025-04-01-preview"
  name                      = azurecaf_name.cognitiveservices_name.name
  parent_id                 = data.azurerm_resource_group.resource_group.id
  location                  = var.location
  schema_validation_enabled = false

  body = {


    kind = "AIServices",
    sku = {
      name = "S0"
    }
    identity = {
      type = "UserAssigned",
      userAssignedIdentities = {
        "${var.user_assigned_managed_identity_id}" = {}
      }
    }

    properties = {
      # Support both Entra ID and API Key authentication for underlining Cognitive Services account
      disableLocalAuth = false

      # Specifies that this is an AI Foundry resource
      allowProjectManagement = true

      # Set custom subdomain name for DNS names created for this Foundry resource
      customSubDomainName = azurecaf_name.cognitiveservices_name.name

      # Network-related controls
      # Disable public access but allow Trusted Azure Services exception
      publicNetworkAccess = "Disabled"
      networkAcls = {
        defaultAction = "Allow"
      }

      # Enable VNet injection for Standard Agents
      networkInjections = [
        {
          scenario                   = "agent"
          subnetArmId                = var.ai_foundry_agent_service_subnet_id
          useMicrosoftManagedNetwork = false
        }
      ]
    }
  }
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
  cognitive_account_id = azapi_resource.ai_foundry.id
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
  name                           = azapi_resource.ai_foundry.name
  resource_group_name            = var.resource_group_name
  tags                           = var.tags
  resource_token                 = var.resource_token
  private_connection_resource_id = azapi_resource.ai_foundry.id
  location                       = var.location
  subnet_id                      = var.subnet_id
  subresource_names              = ["account"]
  is_manual_connection           = false
}

resource "azurerm_monitor_diagnostic_setting" "openai_logging" {
  name                       = "openai-logging"
  target_resource_id         = azapi_resource.ai_foundry.id
  log_analytics_workspace_id = var.log_analytics_workspace_id

  enabled_log {
    category = "RequestResponse"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

resource "azapi_resource" "ai_foundry_project" {
  depends_on = [
    azapi_resource.ai_foundry,
    module.private_endpoint
  ]

  type                      = "Microsoft.CognitiveServices/accounts/projects@2025-04-01-preview"
  name                      = azurecaf_name.cognitiveservices_name.name
  parent_id                 = azapi_resource.ai_foundry.id
  location                  = var.location
  schema_validation_enabled = false

  body = {
    sku = {
      name = "S0"
    }
    identity = {
      type = "UserAssigned",
      userAssignedIdentities = {
        "${var.user_assigned_managed_identity_id}" = {}
      }
    }

    properties = {
      displayName = azurecaf_name.cognitiveservices_name.name
      description = "A project for the AI Foundry account with network secured deployed Agent"
    }
  }

  response_export_values = [
    "identity.principalId",
    "properties.internalId"
  ]
}

resource "azapi_resource" "conn_cosmosdb" {
  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  name                      = var.cosmosdb_account_name
  parent_id                 = azapi_resource.ai_foundry_project.id
  schema_validation_enabled = false

  depends_on = [
    azapi_resource.ai_foundry_project
  ]

  body = {
    name = var.cosmosdb_account_name
    properties = {
      category = "CosmosDb"
      target   = var.cosmosdb_account_endpoint
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.cosmosdb_account_id
        location   = var.location
      }
    }
  }
}

## Create the AI Foundry project connection to Azure Storage Account
##
resource "azapi_resource" "conn_storage" {
  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  name                      = var.storage_account_name
  parent_id                 = azapi_resource.ai_foundry_project.id
  schema_validation_enabled = false

  depends_on = [
    azapi_resource.ai_foundry_project
  ]

  body = {
    name = var.storage_account_name
    properties = {
      category = "AzureStorageAccount"
      target   = var.storage_account_primary_blob_endpoint
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ResourceId = var.storage_account_id
        location   = var.location
      }
    }
  }

  response_export_values = [
    "identity.principalId"
  ]
}

## Create the AI Foundry project connection to AI Search
##
resource "azapi_resource" "conn_aisearch" {
  type                      = "Microsoft.CognitiveServices/accounts/projects/connections@2025-04-01-preview"
  name                      = var.ai_search_service_name
  parent_id                 = azapi_resource.ai_foundry_project.id
  schema_validation_enabled = false

  depends_on = [
    azapi_resource.ai_foundry_project
  ]

  body = {
    name = var.ai_search_service_name
    properties = {
      category = "CognitiveSearch"
      target   = "https://${var.ai_search_service_name}.search.windows.net"
      authType = "AAD"
      metadata = {
        ApiType    = "Azure"
        ApiVersion = "2024-05-01-preview"
        ResourceId = var.ai_search_service_id
        location   = var.location
      }
    }
  }

  response_export_values = [
    "identity.principalId"
  ]
}

resource "azurerm_role_assignment" "cosmosdb_operator_ai_foundry_project" {
  name                 = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${var.user_assigned_managed_identity_principal_id}${var.cosmosdb_account_name}cosmosdboperator")
  scope                = var.cosmosdb_account_id
  role_definition_name = "Cosmos DB Operator"
  principal_id         = var.user_assigned_managed_identity_principal_id
}

resource "azurerm_role_assignment" "storage_blob_data_contributor_ai_foundry_project" {
  name                 = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${var.user_assigned_managed_identity_principal_id}${var.storage_account_name}storageblobdatacontributor")
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = var.user_assigned_managed_identity_principal_id
}

resource "azurerm_role_assignment" "search_index_data_contributor_ai_foundry_project" {
  name                 = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${var.user_assigned_managed_identity_principal_id}${var.ai_search_service_name}searchindexdatacontributor")
  scope                = var.ai_search_service_id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = var.user_assigned_managed_identity_principal_id
}

resource "azurerm_role_assignment" "search_service_contributor_ai_foundry_project" {
  name                 = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${var.user_assigned_managed_identity_principal_id}${var.ai_search_service_name}searchservicecontributor")
  scope                = var.ai_search_service_id
  role_definition_name = "Search Service Contributor"
  principal_id         = var.user_assigned_managed_identity_principal_id
}

## Pause 60 seconds to allow for role assignments to propagate
##
resource "time_sleep" "wait_rbac" {
  depends_on = [
    azurerm_role_assignment.cosmosdb_operator_ai_foundry_project,
    azurerm_role_assignment.storage_blob_data_contributor_ai_foundry_project,
    azurerm_role_assignment.search_index_data_contributor_ai_foundry_project,
    azurerm_role_assignment.search_service_contributor_ai_foundry_project
  ]
  create_duration = "60s"
}

resource "azapi_resource" "ai_foundry_project_capability_host" {
  depends_on = [
    azapi_resource.conn_aisearch,
    azapi_resource.conn_cosmosdb,
    azapi_resource.conn_storage,
    time_sleep.wait_rbac
  ]
  type                      = "Microsoft.CognitiveServices/accounts/projects/capabilityHosts@2025-04-01-preview"
  name                      = "caphostproj"
  parent_id                 = azapi_resource.ai_foundry_project.id
  schema_validation_enabled = false

  body = {
    properties = {
      capabilityHostKind = "Agents"
      vectorStoreConnections = [
        var.ai_search_service_name
      ]
      storageConnections = [
        var.storage_account_name
      ]
      threadStorageConnections = [
        var.cosmosdb_account_name
      ]
    }
  }
}

locals {
  project_id_guid = "${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 0, 8)}-${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 8, 4)}-${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 12, 4)}-${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 16, 4)}-${substr(azapi_resource.ai_foundry_project.output.properties.internalId, 20, 12)}"
}

resource "azurerm_cosmosdb_sql_role_assignment" "cosmosdb_db_sql_role_aifp_user_thread_message_store" {
  depends_on = [
    azapi_resource.ai_foundry_project_capability_host
  ]
  name                = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${var.user_assigned_managed_identity_principal_id}userthreadmessage_dbsqlrole")
  resource_group_name = var.resource_group_name
  account_name        = var.cosmosdb_account_name
  scope               = "${var.cosmosdb_account_id}/dbs/enterprise_memory/colls/${local.project_id_guid}-thread-message-store"
  role_definition_id  = "${var.cosmosdb_account_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = var.user_assigned_managed_identity_principal_id
}

resource "azurerm_cosmosdb_sql_role_assignment" "cosmosdb_db_sql_role_aifp_system_thread_name" {
  depends_on = [
    azurerm_cosmosdb_sql_role_assignment.cosmosdb_db_sql_role_aifp_user_thread_message_store
  ]
  name                = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${var.user_assigned_managed_identity_principal_id}systemthread_dbsqlrole")
  resource_group_name = var.resource_group_name
  account_name        = var.cosmosdb_account_name
  scope               = "${var.cosmosdb_account_id}/dbs/enterprise_memory/colls/${local.project_id_guid}-system-thread-message-store"
  role_definition_id  = "${var.cosmosdb_account_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = var.user_assigned_managed_identity_principal_id
}

resource "azurerm_cosmosdb_sql_role_assignment" "cosmosdb_db_sql_role_aifp_entity_store_name" {
  depends_on = [
    azurerm_cosmosdb_sql_role_assignment.cosmosdb_db_sql_role_aifp_system_thread_name
  ]
  name                = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${var.user_assigned_managed_identity_principal_id}entitystore_dbsqlrole")
  resource_group_name = var.resource_group_name
  account_name        = var.cosmosdb_account_name
  scope               = "${var.cosmosdb_account_id}/dbs/enterprise_memory/colls/${local.project_id_guid}-agent-entity-store"
  role_definition_id  = "${var.cosmosdb_account_id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002"
  principal_id        = var.user_assigned_managed_identity_principal_id
}

## Create the necessary data plane role assignments to the Azure Storage Account containers created by the AI Foundry Project
##
resource "azurerm_role_assignment" "storage_blob_data_owner_ai_foundry_project" {
  depends_on = [
    azapi_resource.ai_foundry_project_capability_host
  ]
  name                 = uuidv5("dns", "${azapi_resource.ai_foundry_project.name}${var.user_assigned_managed_identity_principal_id}${var.storage_account_name}storageblobdataowner")
  scope                = var.storage_account_id
  role_definition_name = "Storage Blob Data Owner"
  principal_id         = var.user_assigned_managed_identity_principal_id
  condition_version    = "2.0"
  condition            = <<-EOT
  (
    (
      !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags/read'})
      AND  !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/filter/action'})
      AND  !(ActionMatches{'Microsoft.Storage/storageAccounts/blobServices/containers/blobs/tags/write'})
    )
    OR
    (@Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringStartsWithIgnoreCase '${local.project_id_guid}'
    AND @Resource[Microsoft.Storage/storageAccounts/blobServices/containers:name] StringLikeIgnoreCase '*-azureml-agent')
  )
  EOT
}
