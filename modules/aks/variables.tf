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

variable "kubernetes_version" {
  description = "Kubernetes version"
  type        = string
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
}

variable "aks_subnet_id" {
  description = "ID of the AKS subnet"
  type        = string
}

variable "enable_pod_identity" {
  description = "Enable pod identity"
  type        = bool
  default     = true
}

variable "enable_network_policy" {
  description = "Enable network policy"
  type        = bool
  default     = true
}

variable "network_policy" {
  description = "Network policy provider"
  type        = string
  default     = "azure"
}

variable "log_analytics_workspace_id" {
  description = "Log Analytics workspace ID"
  type        = string
  default     = null
}

variable "key_vault_id" {
  description = "Key Vault ID for storing secrets"
  type        = string
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
}
