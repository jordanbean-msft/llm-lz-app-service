output "cosmosdb_account_name" {
  value = azurerm_cosmosdb_account.cosmosdb_account.name
}

output "cosmosdb_account_endpoint" {
  value = azurerm_cosmosdb_account.cosmosdb_account.endpoint
}

output "cosmosdb_account_key" {
  value     = azurerm_cosmosdb_account.cosmosdb_account.primary_key
  sensitive = true
}

output "cosmosdb_sql_database_name" {
  value = azurerm_cosmosdb_sql_database.cosmosdb_sql_database.name
}

output "ingestion_cosmosdb_sql_container_name" {
  value = azurerm_cosmosdb_sql_container.ingestion_cosmosdb_sql_container.name
}

output "ingestion_profile_cosmosdb_sql_container_name" {
  value = azurerm_cosmosdb_sql_container.ingestion_profile_cosmosdb_sql_container.name
}
