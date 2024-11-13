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
    azapi = {
      source  = "Azure/azapi"
      version = "2.0.1"
    }
  }
}

data "azurerm_virtual_network" "vnet" {
  name                = var.virtual_network_name
  resource_group_name = var.resource_group_name
}

data "azurerm_subnet" "app_service_subnet" {
  name                 = var.app_service_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
}

data "azurerm_subnet" "function_app_subnet" {
  name                 = var.function_app_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
}

data "azurerm_subnet" "private_endpoint_subnet" {
  name                 = var.private_endpoint_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.virtual_network_name
}

# resource "azapi_update_resource" "service_endpoint_delegation" {
#   for_each    = { for subnet in var.subnets : subnet.name => subnet }
#   type        = "Microsoft.Network/virtualNetworks/subnets@2024-03-01"
#   resource_id = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${var.virtual_network_name}/subnets/${each.key}"

#   body = jsonencode({
#     properties = {
#       delegations = [
#         {
#           name = each.value.delegation_name
#           properties = {
#             serviceName = each.value.delegation_name
#           }
#         }
#       ]
#     }
#   })
# }

# module "network_security_group" {
#   for_each                    = { for subnet in var.subnets : subnet.name => subnet }
#   source                      = "../network_security_group"
#   resource_group_name         = var.resource_group_name
#   tags                        = var.tags
#   resource_token              = var.resource_token
#   location                    = var.location
#   network_security_rules      = each.value.network_security_rules
#   subnet_id                   = "/subscriptions/${var.subscription_id}/resourceGroups/${var.resource_group_name}/providers/Microsoft.Network/virtualNetworks/${var.virtual_network_name}/subnets/${each.key}"
#   subnet_name                 = each.key
#   network_security_group_name = each.value.network_security_group_name
#   subscription_id             = var.subscription_id
#   virtual_network_name        = var.virtual_network_name
# }
