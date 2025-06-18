terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~>3.1"
    }
  }
}

provider "azurerm" {
  features {}
}

resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

resource "random_password" "sql_password" {
  length           = 16
  special          = true
  override_special = "!#$%&" # Caracteres especiales seguros para cadenas de conexión
  min_upper        = 1
  min_lower        = 1
  min_numeric      = 1
  min_special      = 1
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}-${random_string.suffix.result}"
  location = var.location
}

resource "azurerm_mssql_server" "sqlserver" {
  name                         = "${var.sql_server_name}-${random_string.suffix.result}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = random_password.sql_password.result
}

resource "azurerm_mssql_database" "db" {
  name      = var.sql_database_name
  server_id = azurerm_mssql_server.sqlserver.id
  sku_name  = "Basic"
}

resource "azurerm_mssql_firewall_rule" "powerbi_rule" {
  name             = "AllowPowerBI"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = var.powerbi_client_ip
  end_ip_address   = var.powerbi_client_ip
}

resource "azurerm_mssql_firewall_rule" "azure_services_rule" {
  name             = "AllowAllWindowsAzureIps"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}