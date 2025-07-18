output "cosmosdb_account_id" {
  value = azurerm_cosmosdb_account.cosmosdb_account.id
}

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
