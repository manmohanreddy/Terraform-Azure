locals {
  resource_prefix = "${lower(var.company_name)}-${lower(var.project_name)}-${var.location_short}"
  environment_prefix = "${local.resource_prefix}-${var.environment}"

  common_tags = merge(
    var.tags,
    {
      Environment = var.environment
      CreatedDate = timestamp()
      Project     = var.project_name
      Company     = var.company_name
    }
  )
}

# Resource Group
resource "azurerm_resource_group" "main" {
  name       = "${local.environment_prefix}-rg"
  location   = var.location
  tags       = local.common_tags
}

# Networking Module
module "networking" {
  source = "./modules/networking"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  environment_prefix  = local.environment_prefix

  vnet_address_space  = var.vnet_address_space
  subnet_config       = var.subnet_config

  tags                = local.common_tags
}

# Security Module
module "security" {
  source = "./modules/security"

  resource_group_name  = azurerm_resource_group.main.name
  location             = azurerm_resource_group.main.location
  environment          = var.environment
  environment_prefix   = local.environment_prefix

  enable_key_vault     = var.enable_key_vault
  key_vault_sku_name   = var.key_vault_sku_name

  tags                 = local.common_tags
}

# Storage Module
module "storage" {
  source = "./modules/storage"

  count = var.enable_storage_account ? 1 : 0

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  environment_prefix  = local.environment_prefix

  storage_account_tier = var.storage_account_tier

  tags                = local.common_tags
}

# Monitoring Module
module "monitoring" {
  source = "./modules/monitoring"

  count = var.enable_monitoring ? 1 : 0

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  environment_prefix  = local.environment_prefix

  log_analytics_retention_days = var.log_analytics_retention_days

  tags                = local.common_tags
}

# Database Module
module "database" {
  source = "./modules/database"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  environment_prefix  = local.environment_prefix

  enable_postgresql   = var.enable_postgresql
  postgresql_version  = var.postgresql_version
  postgresql_sku_name = var.postgresql_sku_name
  postgresql_storage_mb = var.postgresql_storage_mb

  enable_mysql        = var.enable_mysql
  mysql_version       = var.mysql_version

  postgresql_subnet_id = module.networking.private_endpoint_subnet_id
  mysql_subnet_id      = module.networking.private_endpoint_subnet_id

  key_vault_id        = module.security.key_vault_id

  tags                = local.common_tags
}

# AKS Module
module "aks" {
  source = "./modules/aks"

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  environment_prefix  = local.environment_prefix

  kubernetes_version  = var.kubernetes_version
  node_pool_config    = var.node_pool_config

  aks_subnet_id       = module.networking.aks_subnet_id

  enable_pod_identity = var.enable_pod_identity
  enable_network_policy = var.enable_network_policy
  network_policy      = var.network_policy

  log_analytics_workspace_id = var.enable_monitoring ? module.monitoring[0].log_analytics_workspace_id : null

  key_vault_id        = module.security.key_vault_id

  tags                = local.common_tags
}

# Load Balancer Module
module "loadbalancer" {
  source = "./modules/loadbalancer"

  count = var.enable_app_gateway ? 1 : 0

  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  environment         = var.environment
  environment_prefix  = local.environment_prefix

  app_gateway_sku     = var.app_gateway_sku

  vnet_id             = module.networking.vnet_id
  app_gateway_subnet_id = module.networking.app_gateway_subnet_id

  aks_backend_pool_id = module.aks.aks_backend_pool_id

  tags                = local.common_tags
}

# Resource Lock for Critical Resources (Production only)
resource "azurerm_management_lock" "resource_group_lock" {
  count       = var.resource_locks_enabled && var.environment == "prod" ? 1 : 0
  name        = "${local.environment_prefix}-rg-lock"
  scope       = azurerm_resource_group.main.id
  lock_level  = "CanNotDelete"
  notes       = "Production resource group - prevents accidental deletion"
}
