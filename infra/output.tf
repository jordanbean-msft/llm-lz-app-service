output "AZURE_LOCATION" {
  value = var.location
}
output "AZURE_RESOURCE_GROUP" {
  value = var.resource_group_name
}
output "FUNCTION_APP_ENDPOINT" {
  value = module.function_app.function_app_endpoint
}
output "APP_SERVICE_ENDPOINT" {
  value = module.app_service.app_service_endpoint
}