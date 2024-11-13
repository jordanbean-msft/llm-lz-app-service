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

variable "user_assigned_identity_object_id" {
  description = "The object id of the user assigned identity"
  type        = string
}

variable "log_analytics_workspace_id" {
  description = "The id of the Log Analytics workspace to send logs to"
  type        = string
}

variable "openai_model_deployments" {
  description = "The OpenAI model deployments"
  type = list(object({
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
}

variable "sku_name" {
  description = "The SKU name of the OpenAI service"
  type        = string
}

variable "chat_model_name" {
  description = "The name of the chat model"
  type        = string
}

variable "embeddings_model_name" {
  description = "The name of the embeddings model"
  type        = string
}