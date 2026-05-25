variable "azure_subscription_id" {
  description = "Azure Subscription ID"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

variable "location" {
  description = "Azure region for resources"
  type        = string
  default     = "East US"
}

variable "location_short" {
  description = "Short code for Azure region (e.g., eus for East US)"
  type        = string
  default     = "eus"
}

variable "company_name" {
  description = "Company name for resource naming"
  type        = string
}

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
  default     = "enterprise"
}

variable "tags" {
  description = "Common tags applied to all resources"
  type        = map(string)
  default = {
    ManagedBy = "Terraform"
    Source    = "terraform-azure"
  }
}

# Networking Variables
variable "vnet_address_space" {
  description = "Address space for virtual network"
  type        = list(string)
  default     = ["10.0.0.0/16"]
}

variable "subnet_config" {
  description = "Subnet configuration"
  type = map(object({
    address_prefixes = list(string)
  }))
  default = {
    "aks-subnet" = {
      address_prefixes = ["10.0.1.0/24"]
    }
    "app-gateway-subnet" = {
      address_prefixes = ["10.0.2.0/24"]
    }
    "private-endpoint-subnet" = {
      address_prefixes = ["10.0.3.0/24"]
    }
  }
}

# AKS Variables
variable "kubernetes_version" {
  description = "Kubernetes version for AKS cluster"
  type        = string
  default     = "1.29"
}

variable "node_pool_config" {
  description = "Node pool configuration"
  type = object({
    initial_count       = number
    min_count          = number
    max_count          = number
    vm_size            = string
    enable_auto_scaling = bool
    node_labels        = map(string)
    node_taints        = optional(list(any), [])
  })
  default = {
    initial_count       = 3
    min_count          = 3
    max_count          = 10
    vm_size            = "Standard_D2s_v3"
    enable_auto_scaling = true
    node_labels = {
      environment = "prod"
      workload    = "general"
    }
  }
}

variable "enable_pod_identity" {
  description = "Enable Azure AD Pod Identity"
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Enable Azure Network Policy"
  type        = bool
  default     = true
}

variable "network_policy" {
  description = "Network policy provider"
  type        = string
  default     = "azure"
}

# Database Variables
variable "enable_postgresql" {
  description = "Enable PostgreSQL database"
  type        = bool
  default     = true
}

variable "postgresql_version" {
  description = "PostgreSQL server version"
  type        = string
  default     = "15"
}

variable "postgresql_sku_name" {
  description = "PostgreSQL SKU name"
  type        = string
  default     = "B_Standard_B1ms"
}

variable "postgresql_storage_mb" {
  description = "PostgreSQL storage in MB"
  type        = number
  default     = 32768
}

variable "enable_mysql" {
  description = "Enable MySQL database"
  type        = bool
  default     = false
}

variable "mysql_version" {
  description = "MySQL server version"
  type        = string
  default     = "8.0.37"
}

# Storage Variables
variable "enable_storage_account" {
  description = "Enable Azure Storage Account"
  type        = bool
  default     = true
}

variable "storage_account_tier" {
  description = "Storage account tier"
  type        = string
  default     = "Standard"
  validation {
    condition     = contains(["Standard", "Premium"], var.storage_account_tier)
    error_message = "Storage account tier must be Standard or Premium."
  }
}

# Monitoring Variables
variable "enable_monitoring" {
  description = "Enable Azure Monitor, Application Insights, and Log Analytics"
  type        = bool
  default     = true
}

variable "log_analytics_retention_days" {
  description = "Log Analytics workspace retention days"
  type        = number
  default     = 30
  validation {
    condition     = var.log_analytics_retention_days >= 7 && var.log_analytics_retention_days <= 730
    error_message = "Retention days must be between 7 and 730."
  }
}

# Security Variables
variable "enable_key_vault" {
  description = "Enable Azure Key Vault"
  type        = bool
  default     = true
}

variable "key_vault_sku_name" {
  description = "Key Vault SKU name"
  type        = string
  default     = "standard"
  validation {
    condition     = contains(["standard", "premium"], var.key_vault_sku_name)
    error_message = "Key Vault SKU must be standard or premium."
  }
}

# Load Balancer Variables
variable "enable_app_gateway" {
  description = "Enable Application Gateway"
  type        = bool
  default     = true
}

variable "app_gateway_sku" {
  description = "Application Gateway SKU"
  type        = string
  default     = "Standard_v2"
}

# Cost Optimization
variable "auto_shutdown_enabled" {
  description = "Enable auto-shutdown for dev/staging environments"
  type        = bool
  default     = false
}

variable "resource_locks_enabled" {
  description = "Enable resource locks on critical resources"
  type        = bool
  default     = true
}
