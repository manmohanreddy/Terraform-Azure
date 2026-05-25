output "app_gateway_id" {
  description = "ID of the Application Gateway"
  value       = azurerm_application_gateway.main.id
}

output "app_gateway_name" {
  description = "Name of the Application Gateway"
  value       = azurerm_application_gateway.main.name
}

output "app_gateway_public_ip" {
  description = "Public IP of the Application Gateway"
  value       = azurerm_public_ip.app_gateway.ip_address
}

output "app_gateway_backend_pool_id" {
  description = "ID of the default backend pool"
  value       = azurerm_application_gateway_backend_pool.aks.id
}

output "app_gateway_backend_pool_name" {
  description = "Name of the default backend pool"
  value       = azurerm_application_gateway_backend_pool.aks.name
}

output "public_ip_id" {
  description = "ID of the public IP"
  value       = azurerm_public_ip.app_gateway.id
}
