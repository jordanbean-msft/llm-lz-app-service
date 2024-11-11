variable "location" {
  description = "The supported Azure location where the resource deployed"
  type        = string
}

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

variable "subnet_id" {
  description = "The resource id of the subnet to deploy the private endpoint into"
  type        = string
}

variable "private_endpoint_subnet_id" {
  description = "The resource id of the subnet to deploy the private endpoint into"
  type        = string
}

variable "managed_identity_id" {
  description = "The resource id of the managed identity to use for the function app"
  type        = string
}

variable "sku_name" {
  description = "The SKU name of the app service plan"
  type        = string
}

variable "storage_account_name" {
  description = "The name of the storage account to use for the function app"
  type        = string
}

variable "application_insights_key" {
  description = "The key for the Application Insights instance"
  type        = string
}

variable "application_insights_connection_string" {
  description = "The connection string for the Application Insights instance"
  type        = string
}