output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.main.name
}

output "resource_group_id" {
  description = "ID of the resource group"
  value       = azurerm_resource_group.main.id
}

# Networking Outputs
output "vnet_id" {
  description = "ID of the virtual network"
  value       = module.networking.vnet_id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = module.networking.vnet_name
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = module.networking.aks_subnet_id
}

output "app_gateway_subnet_id" {
  description = "ID of the Application Gateway subnet"
  value       = module.networking.app_gateway_subnet_id
}

output "private_endpoint_subnet_id" {
  description = "ID of the private endpoint subnet"
  value       = module.networking.private_endpoint_subnet_id
}

# AKS Outputs
output "kubernetes_cluster_name" {
  description = "Name of the AKS cluster"
  value       = module.aks.kubernetes_cluster_name
}

output "kubernetes_cluster_id" {
  description = "ID of the AKS cluster"
  value       = module.aks.kubernetes_cluster_id
}

output "kube_config_raw" {
  description = "Raw Kubernetes config file content"
  value       = module.aks.kube_config_raw
  sensitive   = true
}

output "aks_managed_identity_principal_id" {
  description = "Principal ID of the AKS cluster managed identity"
  value       = module.aks.aks_managed_identity_principal_id
}

output "aks_node_resource_group_name" {
  description = "Name of the node resource group"
  value       = module.aks.aks_node_resource_group_name
}

# Kubernetes Configuration Command
output "configure_kubectl" {
  description = "Command to configure kubectl"
  value       = "az aks get-credentials --resource-group ${azurerm_resource_group.main.name} --name ${module.aks.kubernetes_cluster_name} --overwrite-existing"
}

# Security Outputs
output "key_vault_id" {
  description = "ID of the Key Vault"
  value       = module.security.key_vault_id
}

output "key_vault_name" {
  description = "Name of the Key Vault"
  value       = module.security.key_vault_name
}

output "key_vault_uri" {
  description = "URI of the Key Vault"
  value       = module.security.key_vault_uri
}

# Storage Outputs
output "storage_account_id" {
  description = "ID of the storage account"
  value       = var.enable_storage_account ? module.storage[0].storage_account_id : null
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = var.enable_storage_account ? module.storage[0].storage_account_name : null
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint of the storage account"
  value       = var.enable_storage_account ? module.storage[0].storage_account_primary_blob_endpoint : null
}

# Database Outputs
output "postgresql_server_id" {
  description = "ID of the PostgreSQL server"
  value       = var.enable_postgresql ? module.database.postgresql_server_id : null
}

output "postgresql_server_name" {
  description = "Name of the PostgreSQL server"
  value       = var.enable_postgresql ? module.database.postgresql_server_name : null
}

output "postgresql_server_fqdn" {
  description = "FQDN of the PostgreSQL server"
  value       = var.enable_postgresql ? module.database.postgresql_server_fqdn : null
}

output "mysql_server_id" {
  description = "ID of the MySQL server"
  value       = var.enable_mysql ? module.database.mysql_server_id : null
}

output "mysql_server_name" {
  description = "Name of the MySQL server"
  value       = var.enable_mysql ? module.database.mysql_server_name : null
}

output "mysql_server_fqdn" {
  description = "FQDN of the MySQL server"
  value       = var.enable_mysql ? module.database.mysql_server_fqdn : null
}

# Monitoring Outputs
output "log_analytics_workspace_id" {
  description = "ID of the Log Analytics workspace"
  value       = var.enable_monitoring ? module.monitoring[0].log_analytics_workspace_id : null
}

output "log_analytics_workspace_name" {
  description = "Name of the Log Analytics workspace"
  value       = var.enable_monitoring ? module.monitoring[0].log_analytics_workspace_name : null
}

output "application_insights_id" {
  description = "ID of the Application Insights instance"
  value       = var.enable_monitoring ? module.monitoring[0].application_insights_id : null
}

output "application_insights_instrumentation_key" {
  description = "Instrumentation key for Application Insights"
  value       = var.enable_monitoring ? module.monitoring[0].application_insights_instrumentation_key : null
  sensitive   = true
}

# Load Balancer Outputs
output "app_gateway_id" {
  description = "ID of the Application Gateway"
  value       = var.enable_app_gateway ? module.loadbalancer[0].app_gateway_id : null
}

output "app_gateway_name" {
  description = "Name of the Application Gateway"
  value       = var.enable_app_gateway ? module.loadbalancer[0].app_gateway_name : null
}

output "app_gateway_public_ip" {
  description = "Public IP of the Application Gateway"
  value       = var.enable_app_gateway ? module.loadbalancer[0].app_gateway_public_ip : null
}

output "app_gateway_backend_pool_id" {
  description = "ID of the Application Gateway backend pool"
  value       = var.enable_app_gateway ? module.loadbalancer[0].app_gateway_backend_pool_id : null
}

# Summary
output "deployment_summary" {
  description = "Summary of the deployment"
  value = {
    environment      = var.environment
    location         = azurerm_resource_group.main.location
    company          = var.company_name
    project          = var.project_name
    resource_prefix  = local.resource_prefix
    aks_cluster_name = module.aks.kubernetes_cluster_name
    db_enabled       = var.enable_postgresql || var.enable_mysql
    monitoring_enabled = var.enable_monitoring
  }
}
