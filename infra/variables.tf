variable "location" {
  description = "The Azure region where resources will be created."
  type        = string
  default     = "West US 2"
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
  default     = "rg-upt-tech-analysis-v2"
}

variable "sql_server_name" {
  description = "The name of the SQL Server."
  type        = string
  default     = "sql-upt-tech-analysis-server"
}

variable "sql_database_name" {
  description = "The name of the SQL Database."
  type        = string
  default     = "db-upt-tech-analysis"
}

variable "sql_admin_login" {
  description = "The administrator login for the SQL Server."
  type        = string
  default     = "dbadmin885"
}

variable "sql_admin_password" {
  description = "The administrator password for the SQL Server."
  type        = string
  sensitive   = true
}

variable "powerbi_client_ip" {
  description = "The public IP address of the client machine running Power BI."
  type        = string
  default     = "0.0.0.0" # Cambia esto a tu IP si es necesario
}
