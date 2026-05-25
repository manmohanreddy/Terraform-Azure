output "storage_account_id" {
  description = "ID of the storage account"
  value       = azurerm_storage_account.main.id
}

output "storage_account_name" {
  description = "Name of the storage account"
  value       = azurerm_storage_account.main.name
}

output "storage_account_primary_blob_endpoint" {
  description = "Primary blob endpoint"
  value       = azurerm_storage_account.main.primary_blob_endpoint
}

output "storage_account_primary_file_endpoint" {
  description = "Primary file endpoint"
  value       = azurerm_storage_account.main.primary_file_endpoint
}

output "app_data_container_name" {
  description = "Name of the app data container"
  value       = azurerm_storage_container.app_data.name
}

output "backups_container_name" {
  description = "Name of the backups container"
  value       = azurerm_storage_container.backups.name
}

output "logs_container_name" {
  description = "Name of the logs container"
  value       = azurerm_storage_container.logs.name
}

output "app_share_name" {
  description = "Name of the app file share"
  value       = azurerm_storage_share.app_share.name
}
