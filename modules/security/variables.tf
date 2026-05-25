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

variable "enable_key_vault" {
  description = "Enable Key Vault"
  type        = bool
  default     = true
}

variable "key_vault_sku_name" {
  description = "Key Vault SKU name"
  type        = string
  default     = "standard"
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
