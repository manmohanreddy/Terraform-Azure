output "vnet_id" {
  description = "ID of the virtual network"
  value       = azurerm_virtual_network.main.id
}

output "vnet_name" {
  description = "Name of the virtual network"
  value       = azurerm_virtual_network.main.name
}

output "aks_subnet_id" {
  description = "ID of the AKS subnet"
  value       = azurerm_subnet.main["aks-subnet"].id
}

output "aks_subnet_name" {
  description = "Name of the AKS subnet"
  value       = azurerm_subnet.main["aks-subnet"].name
}

output "app_gateway_subnet_id" {
  description = "ID of the Application Gateway subnet"
  value       = azurerm_subnet.main["app-gateway-subnet"].id
}

output "app_gateway_subnet_name" {
  description = "Name of the Application Gateway subnet"
  value       = azurerm_subnet.main["app-gateway-subnet"].name
}

output "private_endpoint_subnet_id" {
  description = "ID of the private endpoint subnet"
  value       = azurerm_subnet.main["private-endpoint-subnet"].id
}

output "private_endpoint_subnet_name" {
  description = "Name of the private endpoint subnet"
  value       = azurerm_subnet.main["private-endpoint-subnet"].name
}

output "aks_nsg_id" {
  description = "ID of the AKS network security group"
  value       = azurerm_network_security_group.aks.id
}

output "app_gateway_nsg_id" {
  description = "ID of the Application Gateway network security group"
  value       = azurerm_network_security_group.app_gateway.id
}
