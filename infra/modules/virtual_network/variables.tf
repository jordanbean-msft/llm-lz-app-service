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
