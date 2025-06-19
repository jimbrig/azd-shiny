# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "${var.environment_name}-rg"
  location = var.location

  tags = {
    environment = var.environment_name
    project     = "r-shiny-app"
    "azd-env-name" = var.environment_name
  }
}

# Log Analytics Workspace for Container Apps
resource "azurerm_log_analytics_workspace" "logs" {
  name                = "${var.environment_name}-logs"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    environment = var.environment_name
    project     = "r-shiny-app"
  }
}

# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = replace("${var.environment_name}acr", "-", "")
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = false # Use managed identity instead

  tags = {
    environment = var.environment_name
    project     = "r-shiny-app"
  }
}

# User Assigned Managed Identity
resource "azurerm_user_assigned_identity" "container_app_identity" {
  name                = "${var.environment_name}-container-identity"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  tags = {
    environment = var.environment_name
    project     = "r-shiny-app"
  }
}

# Role assignment for ACR pull
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.container_app_identity.principal_id
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                = "${var.environment_name}-kv"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  # Enable RBAC instead of access policies
  enable_rbac_authorization = true

  tags = {
    environment = var.environment_name
    project     = "r-shiny-app"
  }
}

# Data source for current client configuration
data "azurerm_client_config" "current" {}

# Key Vault role assignment for container app identity
resource "azurerm_role_assignment" "kv_secrets_user" {
  scope                = azurerm_key_vault.kv.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.container_app_identity.principal_id
}

# Sample Key Vault secret for R Shiny app configuration
resource "azurerm_key_vault_secret" "app_secret" {
  name         = "shiny-app-secret"
  value        = var.app_secret_value
  key_vault_id = azurerm_key_vault.kv.id

  depends_on = [
    azurerm_role_assignment.kv_secrets_user
  ]

  tags = {
    environment = var.environment_name
    project     = "r-shiny-app"
  }
}

# Container Apps Environment
resource "azurerm_container_app_environment" "env" {
  name                       = "${var.environment_name}-env"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  log_analytics_workspace_id = azurerm_log_analytics_workspace.logs.id

  tags = {
    environment = var.environment_name
    project     = "r-shiny-app"
  }
}

# Container App for R Shiny
resource "azurerm_container_app" "shiny" {
  name                         = "${var.environment_name}-shiny"
  container_app_environment_id = azurerm_container_app_environment.env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.container_app_identity.id]
  }

  registry {
    server   = azurerm_container_registry.acr.login_server
    identity = azurerm_user_assigned_identity.container_app_identity.id
  }

  template {
    container {
      name   = "shiny-app"
      image  = "${azurerm_container_registry.acr.login_server}/${var.image_name}:latest"
      cpu    = 0.5
      memory = "1Gi"

      env {
        name  = "PORT"
        value = "3838"
      }

      env {
        name        = "APP_SECRET"
        secret_name = "app-secret"
      }
    }

    min_replicas = var.min_replicas
    max_replicas = var.max_replicas
  }

  ingress {
    allow_insecure_connections = false
    external_enabled           = true
    target_port                = 3838
    transport                  = "http"

    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }

  secret {
    name  = "app-secret"
    value = var.app_secret_value
  }

  tags = {
    environment    = var.environment_name
    project        = "r-shiny-app"
    "azd-service-name" = "shiny"
  }

  depends_on = [
    azurerm_role_assignment.acr_pull
  ]
}
