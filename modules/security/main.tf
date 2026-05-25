data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "main" {
  name                       = substr("${replace(var.environment_prefix, "-", "")}kv", 0, 24)
  location                   = var.location
  resource_group_name        = var.resource_group_name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = var.key_vault_sku_name
  enabled_for_disk_encryption = true
  enabled_for_deployment     = true
  soft_delete_retention_days = 7
  purge_protection_enabled   = var.environment == "prod"
  tags                       = var.tags

  network_rules {
    default_action = "Allow"
    bypass         = ["AzureServices"]
  }
}

# Access policy for current user
resource "azurerm_key_vault_access_policy" "current_user" {
  key_vault_id = azurerm_key_vault.main.id
  tenant_id    = data.azurerm_client_config.current.tenant_id
  object_id    = data.azurerm_client_config.current.object_id

  key_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Update",
    "Purge"
  ]

  secret_permissions = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Purge"
  ]

  certificate_permissions = [
    "Get",
    "List",
    "Create",
    "Delete",
    "Update",
    "Purge"
  ]
}

# Azure Managed Identity for AKS
resource "azurerm_key_vault_access_policy" "aks" {
  count            = 0  # Will be set by parent module
  key_vault_id     = azurerm_key_vault.main.id
  tenant_id        = data.azurerm_client_config.current.tenant_id
  object_id        = ""  # Pass from AKS module

  secret_permissions = [
    "Get",
    "List"
  ]

  key_permissions = [
    "Get",
    "List"
  ]
}

# Example secret for database credentials
resource "azurerm_key_vault_secret" "database_password" {
  count            = 0  # Set to 1 to enable
  name             = "database-password"
  value            = random_password.database_password[0].result
  key_vault_id     = azurerm_key_vault.main.id
  expiration_date  = timeadd(timestamp(), "8760h")  # 1 year
}

resource "random_password" "database_password" {
  count            = 0
  length           = 32
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}

# Diagnostic settings for Key Vault
resource "azurerm_monitor_diagnostic_setting" "key_vault" {
  count                      = 0  # Set to 1 if monitoring is enabled
  name                       = "${var.environment_prefix}-kv-diag"
  target_resource_id         = azurerm_key_vault.main.id
  log_analytics_workspace_id = ""  # Pass from monitoring module

  enabled_log {
    category = "AuditEvent"
  }

  metric {
    category = "AllMetrics"
    enabled  = true
  }
}
