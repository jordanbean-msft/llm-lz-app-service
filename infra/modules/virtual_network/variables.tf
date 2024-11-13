variable "resource_group_name" {
  description = "The name of the resource group to deploy resources into"
  type        = string
}

variable "tags" {
  description = "A list of tags used for deployed services."
  type        = map(string)
}

variable "resource_token" {
  description = "A suffix string to centrally mitigate resource name collisions."
  type        = string
}

variable "location" {
  description = "Location in which to deploy the network"
  type        = string
}

variable "virtual_network_name" {
  description = "VNET name"
  type        = string
}

variable "app_service_subnet_name" {
  description = "Specifies resource name of the subnet hosting the app."
  type        = string
}

variable "private_endpoint_subnet_name" {
  description = "Specifies resource name of the subnet hosting the private endpoints."
  type        = string
}

variable "function_app_subnet_name" {
  description = "Specifies resource name of the subnet hosting the function app."
  type        = string
}

variable "subnets" {
  description = "List of subnets to update in the virtual network"
  type = list(object({
    name                        = string
    delegation_name             = string
    network_security_group_name = string
    network_security_rules = list(object({
      name                       = string
      priority                   = number
      direction                  = string
      access                     = string
      protocol                   = string
      source_port_range          = string
      destination_port_range     = optional(string)
      destination_port_ranges    = optional(list(string))
      source_address_prefix      = string
      destination_address_prefix = string
    }))
  }))
}

variable "subscription_id" {
  description = "The subscription ID to deploy resources into"
  type        = string
}

# variable "managed_identity_principal_id" {
#   description = "The principal id of the managed identity"
#   type        = string
# }
