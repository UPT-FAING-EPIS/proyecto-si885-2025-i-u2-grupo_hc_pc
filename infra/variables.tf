variable "location" {
  description = "The Azure region where resources will be created."
  type        = string
  default     = "East US 2"
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
  default     = "rg-si885-project-final"
}

variable "sql_server_name" {
  description = "The name of the SQL Server."
  type        = string
  default     = "sql-si885-project-server"
}

variable "sql_database_name" {
  description = "The name of the SQL Database."
  type        = string
  default     = "db-si885-project"
}

variable "sql_admin_login" {
  description = "The administrator login for the SQL Server."
  type        = string
  default     = "sqladmin"
}

variable "sql_admin_password" {
  description = "The administrator password for the SQL Server."
  type        = string
  sensitive   = true
}

variable "powerbi_client_ip" {
  description = "The public IP address of the client machine running Power BI."
  type        = string
  default     = "179.6.56.63"
}
