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

variable "vnet_address_space" {
  description = "Address space for the virtual network"
  type        = list(string)
}

variable "subnet_config" {
  description = "Subnet configuration"
  type = map(object({
    address_prefixes = list(string)
  }))
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
