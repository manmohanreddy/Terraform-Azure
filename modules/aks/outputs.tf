output "kubernetes_cluster_id" {
  description = "ID of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.id
}

output "kubernetes_cluster_name" {
  description = "Name of the AKS cluster"
  value       = azurerm_kubernetes_cluster.main.name
}

output "kube_config" {
  description = "Kubernetes config"
  value       = azurerm_kubernetes_cluster.main.kube_config
  sensitive   = true
}

output "kube_config_raw" {
  description = "Raw kubeconfig"
  value       = azurerm_kubernetes_cluster.main.kube_config_raw
  sensitive   = true
}

output "aks_managed_identity_principal_id" {
  description = "Principal ID of the AKS managed identity"
  value       = azurerm_user_assigned_identity.aks.principal_id
}

output "aks_managed_identity_client_id" {
  description = "Client ID of the AKS managed identity"
  value       = azurerm_user_assigned_identity.aks.client_id
}

output "kubelet_identity_object_id" {
  description = "Object ID of the kubelet identity"
  value       = azurerm_kubernetes_cluster.main.kubelet_identity[0].object_id
}

output "aks_node_resource_group_name" {
  description = "Name of the AKS node resource group"
  value       = azurerm_kubernetes_cluster.main.node_resource_group
}

output "aks_backend_pool_id" {
  description = "ID of the backend pool (for use with load balancer)"
  value       = azurerm_kubernetes_cluster.main.network_profile[0].load_balancer_profile[0].outbound_ip_address_ids
}
