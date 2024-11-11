output "function_app_plan_name" {
  description = "The name of the function app plan"
  value       = azurerm_service_plan.function_app_plan.name
}

output "function_app_name" {
  description = "The name of the function app"
  value       = azurerm_linux_function_app.function_app.name
}