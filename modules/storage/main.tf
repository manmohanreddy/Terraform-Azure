resource "azurerm_storage_account" "main" {
  name                      = substr(replace("${var.environment_prefix}stg", "-", ""), 0, 24)
  resource_group_name       = var.resource_group_name
  location                  = var.location
  account_tier              = var.storage_account_tier
  account_replication_type  = "GRS"
  https_traffic_only_enabled = true
  min_tls_version           = "TLS1_2"
  tags                      = var.tags

  blob_properties {
    cors_rule {
      allowed_headers    = ["*"]
      allowed_methods    = ["GET", "HEAD", "PUT", "POST", "DELETE"]
      allowed_origins    = ["*"]
      exposed_headers    = ["*"]
      max_age_in_seconds = 0
    }

    delete_retention_policy {
      days = 7
    }

    versioning_enabled       = true
    change_feed_enabled      = true
    default_service_version  = "2021-06-08"
    last_access_time_enabled = true
  }

  queue_properties {
    logging {
      delete                = true
      read                  = true
      retention_policy_days = 7
      version               = "1.0"
      write                 = true
    }
  }
}

# Storage Account Network Rules
resource "azurerm_storage_account_network_rules" "main" {
  storage_account_id = azurerm_storage_account.main.id

  default_action             = "Deny"
  bypass                     = ["AzureServices", "Logging"]
  virtual_network_subnet_ids = []  # Add trusted subnet IDs
  ip_rules                   = []  # Add trusted IP addresses
}

# Container for application data
resource "azurerm_storage_container" "app_data" {
  name                  = "appdata"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Container for backups
resource "azurerm_storage_container" "backups" {
  name                  = "backups"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# Container for logs
resource "azurerm_storage_container" "logs" {
  name                  = "logs"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"
}

# File Share for shared storage
resource "azurerm_storage_share" "app_share" {
  name                 = "appshare"
  storage_account_name = azurerm_storage_account.main.name
  quota                = 100
  access_tier          = "Hot"
}

# Storage Account Encryption
resource "azurerm_storage_account_customer_managed_key" "main" {
  count                     = 0  # Set to 1 for CMK
  storage_account_id        = azurerm_storage_account.main.id
  key_vault_id              = ""  # Pass from security module
  key_name                  = ""  # Key name from Key Vault
  user_assigned_identity_id = ""  # Managed identity ID
}

# Lifecycle management
resource "azurerm_storage_management_policy" "main" {
  storage_account_id = azurerm_storage_account.main.id

  rule {
    name    = "delete-old-logs"
    enabled = true
    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["logs/"]
    }
    actions {
      base_blob {
        delete_after_days_since_modification_greater_than = 90
      }
    }
  }

  rule {
    name    = "archive-old-backups"
    enabled = true
    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["backups/"]
    }
    actions {
      base_blob {
        tier_to_archive_after_days_since_modification_greater_than = 30
      }
    }
  }
}
