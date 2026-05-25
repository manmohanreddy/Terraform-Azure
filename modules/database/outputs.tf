output "postgresql_server_id" {
  description = "ID of the PostgreSQL server"
  value       = try(azurerm_postgresql_flexible_server.main[0].id, null)
}

output "postgresql_server_name" {
  description = "Name of the PostgreSQL server"
  value       = try(azurerm_postgresql_flexible_server.main[0].name, null)
}

output "postgresql_server_fqdn" {
  description = "FQDN of the PostgreSQL server"
  value       = try(azurerm_postgresql_flexible_server.main[0].fqdn, null)
}

output "postgresql_database_name" {
  description = "Name of the PostgreSQL database"
  value       = try(azurerm_postgresql_flexible_server_database.main[0].name, null)
}

output "mysql_server_id" {
  description = "ID of the MySQL server"
  value       = try(azurerm_mysql_flexible_server.main[0].id, null)
}

output "mysql_server_name" {
  description = "Name of the MySQL server"
  value       = try(azurerm_mysql_flexible_server.main[0].name, null)
}

output "mysql_server_fqdn" {
  description = "FQDN of the MySQL server"
  value       = try(azurerm_mysql_flexible_server.main[0].fqdn, null)
}

output "mysql_database_name" {
  description = "Name of the MySQL database"
  value       = try(azurerm_mysql_flexible_server_database.main[0].name, null)
}
