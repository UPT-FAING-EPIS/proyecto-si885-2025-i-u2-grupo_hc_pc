output "sql_server_fqdn" {
  description = "The fully qualified domain name of the SQL server."
  value       = azurerm_mssql_server.sqlserver.fully_qualified_domain_name
}

output "sql_database_name" {
  description = "The name of the SQL database."
  value       = azurerm_mssql_database.db.name
}

output "sql_admin_login" {
  description = "The admin login for the SQL server."
  value       = azurerm_mssql_server.sqlserver.administrator_login
}
