output "container_app_url" {
  description = "URL of the R Shiny Container App"
  value       = "https://${azurerm_container_app.shiny.latest_revision_fqdn}"
}

output "container_registry_name" {
  description = "Name of the Container Registry"
  value       = azurerm_container_registry.acr.name
}

output "container_registry_login_server" {
  description = "Login server URL of the Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = azurerm_key_vault.kv.name
}

output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "container_app_environment_name" {
  description = "Name of the Container Apps Environment"
  value       = azurerm_container_app_environment.env.name
}
