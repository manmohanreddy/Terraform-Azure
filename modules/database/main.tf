# PostgreSQL Server
resource "azurerm_postgresql_flexible_server" "main" {
  count = var.enable_postgresql ? 1 : 0

  name                   = "${var.environment_prefix}-psql"
  location               = var.location
  resource_group_name    = var.resource_group_name
  version                = var.postgresql_version
  administrator_login    = "psqladmin"
  administrator_password = random_password.postgresql[0].result
  zone                   = "1"
  storage_mb             = var.postgresql_storage_mb
  sku_name               = var.postgresql_sku_name
  tags                   = var.tags

  # Network connectivity
  delegated_subnet_id = var.postgresql_subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.postgresql[0].id

  # Backup
  backup_retention_days = 7

  # High Availability
  high_availability {
    mode                      = "ZoneRedundant"
    standby_availability_zone = "2"
  }

  # Authentication
  authentication {
    password_auth_enabled = true
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.postgresql[0]
  ]
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  count = var.enable_postgresql ? 1 : 0

  name      = "appdb"
  server_id = azurerm_postgresql_flexible_server.main[0].id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

resource "azurerm_postgresql_flexible_server_configuration" "postgresql" {
  count = var.enable_postgresql ? 1 : 0

  server_id = azurerm_postgresql_flexible_server.main[0].id
  name      = "require_secure_transport"
  value     = "on"
}

# Private DNS Zone for PostgreSQL
resource "azurerm_private_dns_zone" "postgresql" {
  count = var.enable_postgresql ? 1 : 0

  name                = "${var.environment_prefix}.postgres.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "postgresql" {
  count = var.enable_postgresql ? 1 : 0

  name                  = "${var.environment_prefix}-psql-vnet-link"
  private_dns_zone_id   = azurerm_private_dns_zone.postgresql[0].id
  virtual_network_id    = ""  # Will be passed from networking module
  registration_enabled  = true
  resource_group_name   = var.resource_group_name
}

resource "random_password" "postgresql" {
  count            = var.enable_postgresql ? 1 : 0
  length           = 32
  special          = true
  override_special = "!@#$%^&*()-_=+[]{}:?"
}

# Store PostgreSQL password in Key Vault
resource "azurerm_key_vault_secret" "postgresql_password" {
  count = var.enable_postgresql ? 1 : 0

  name         = "postgresql-admin-password"
  value        = random_password.postgresql[0].result
  key_vault_id = var.key_vault_id
}

# MySQL Server
resource "azurerm_mysql_flexible_server" "main" {
  count = var.enable_mysql ? 1 : 0

  name                   = "${var.environment_prefix}-mysql"
  location               = var.location
  resource_group_name    = var.resource_group_name
  version                = var.mysql_version
  administrator_login    = "mysqladmin"
  administrator_password = random_password.mysql[0].result
  zone                   = "1"
  sku_name               = "Standard_B1ms"
  tags                   = var.tags

  # Network connectivity
  delegated_subnet_id = var.mysql_subnet_id
  private_dns_zone_id = azurerm_private_dns_zone.mysql[0].id

  # Backup
  backup_retention_days = 7

  # High Availability
  high_availability {
    mode = "ZoneRedundant"
  }

  depends_on = [
    azurerm_private_dns_zone_virtual_network_link.mysql[0]
  ]
}

resource "azurerm_mysql_flexible_server_database" "main" {
  count = var.enable_mysql ? 1 : 0

  name      = "appdb"
  server_id = azurerm_mysql_flexible_server.main[0].id
  charset   = "utf8"
  collation = "utf8_unicode_ci"
}

# Private DNS Zone for MySQL
resource "azurerm_private_dns_zone" "mysql" {
  count = var.enable_mysql ? 1 : 0

  name                = "${var.environment_prefix}.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
  tags                = var.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  count = var.enable_mysql ? 1 : 0

  name                  = "${var.environment_prefix}-mysql-vnet-link"
  private_dns_zone_id   = azurerm_private_dns_zone.mysql[0].id
  virtual_network_id    = ""  # Will be passed from networking module
  registration_enabled  = true
  resource_group_name   = var.resource_group_name
}

resource "random_password" "mysql" {
  count            = var.enable_mysql ? 1 : 0
  length           = 32
  special          = true
  override_special = "!@#$%^&*()-_=+[]{}:?"
}

# Store MySQL password in Key Vault
resource "azurerm_key_vault_secret" "mysql_password" {
  count = var.enable_mysql ? 1 : 0

  name         = "mysql-admin-password"
  value        = random_password.mysql[0].result
  key_vault_id = var.key_vault_id
}
