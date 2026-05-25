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

variable "log_analytics_retention_days" {
  description = "Log Analytics retention days"
  type        = number
  default     = 30
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
