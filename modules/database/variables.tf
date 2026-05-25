variable "resource_group_name" {
  description = "Name of the resource group"
  type        = string
}

variable "location" {
  description = "Azure location"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "environment_prefix" {
  description = "Prefix for resource naming"
  type        = string
}

variable "enable_postgresql" {
  description = "Enable PostgreSQL"
  type        = bool
  default     = true
}

variable "postgresql_version" {
  description = "PostgreSQL version"
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
  description = "Enable MySQL"
  type        = bool
  default     = false
}

variable "mysql_version" {
  description = "MySQL version"
  type        = string
  default     = "8.0.37"
}

variable "postgresql_subnet_id" {
  description = "Subnet ID for PostgreSQL"
  type        = string
}

variable "mysql_subnet_id" {
  description = "Subnet ID for MySQL"
  type        = string
}

variable "key_vault_id" {
  description = "Key Vault ID for storing secrets"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
