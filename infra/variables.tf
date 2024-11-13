variable "location" {
  description = "The supported Azure location where the resource deployed"
  type        = string
}

variable "principal_id" {
  description = "The Id of the azd service principal to add to deployed keyvault access policies"
  type        = string
  default     = ""
}

variable "resource_group_name" {
  description = "RG for the deployment"
  type        = string
}

variable "environment_name" {
  description = "The name of the environment"
  type        = string
}

variable "network" {
  type = object({
    virtual_network_resource_group_name = string
    virtual_network_name                = string
    private_endpoint_subnet_name        = string
    app_service_subnet_name             = string
    function_app_subnet_name            = string
  })
}

variable "openai" {
  type = object({
    sku_name              = string,
    chat_model_name       = string,
    embeddings_model_name = string,
    model_deployments = list(object({
      model = object({
        format  = string
        name    = string
        version = string
      }),
      sku = object({
        name     = string,
        capacity = optional(number)
      }),
      rai_policy_name = string
    }))
  })
}

variable "storage_account" {
  type = object({
    tier             = string
    replication_type = string
  })
}

variable "ai_search" {
  type = object({
    sku = string
  })
}

variable "function_app" {
  type = object({
    sku_name               = string
    zone_balancing_enabled = bool
  })
}

variable "app_service" {
  type = object({
    sku_name               = string
    zone_balancing_enabled = bool
  })
}

variable "document_intelligence" {
  type = object({
    sku_name = string
  })
}

variable "cosmos_db" {
  type = object({
    document_time_to_live = number
    max_throughput        = number
    zone_redundant        = bool
  })
}