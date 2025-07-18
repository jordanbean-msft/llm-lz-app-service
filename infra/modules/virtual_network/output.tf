output "name" {
  description = "Specifies the name of the virtual network"
  value       = data.azurerm_virtual_network.vnet.name
}

output "vnet_id" {
  description = "Specifies the resource id of the virtual network"
  value       = data.azurerm_virtual_network.vnet.id
}

output "app_service_subnet_id" {
  description = "value of the app_service_subnet_id"
  value       = "${data.azurerm_virtual_network.vnet.id}/subnets/${var.app_service_subnet_name}"
}

output "private_endpoint_subnet_id" {
  description = "value of the private_endpoint_subnet_id"
  value       = "${data.azurerm_virtual_network.vnet.id}/subnets/${var.private_endpoint_subnet_name}"
}

output "ai_foundry_agents_service_subnet_id" {
  value = "${data.azurerm_virtual_network.vnet.id}/subnets/${var.ai_foundry_agents_subnet_name}"
}
