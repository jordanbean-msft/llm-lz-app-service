output "azure_cognitive_services_endpoint" {
  value = azapi_resource.ai_foundry.output.endpoint
}

output "azure_cognitive_services_key" {
  value     = ""
  sensitive = true
}

output "chat_model_name" {
  value = var.chat_model_name
}

output "embeddings_model_name" {
  value = var.embeddings_model_name
}
