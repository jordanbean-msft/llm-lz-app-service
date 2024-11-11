output "app_service_plan_name" {
  description = "The name of the app service plan"
  value       = azurerm_service_plan.app_service_plan.name
}

output "app_service_name" {
  description = "The name of the app service"
  value       = azurerm_linux_web_app.app_service.name
}