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

variable "app_gateway_sku" {
  description = "Application Gateway SKU"
  type        = string
  default     = "Standard_v2"
}

variable "vnet_id" {
  description = "Virtual Network ID"
  type        = string
}

variable "app_gateway_subnet_id" {
  description = "Application Gateway subnet ID"
  type        = string
}

variable "aks_backend_pool_id" {
  description = "AKS backend pool ID"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
