terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
    }
  }
  
  # Backend comentado hasta crear el storage account
  # backend "azurerm" {
  #   resource_group_name  = "rg-upt-tech-analysis-lsnvfq"
  #   storage_account_name = "stterraformstatelsnvfq"
  #   container_name      = "tfstate"
  #   key                 = "upt-tech-analysis.terraform.tfstate"
  # }
}

provider "azurerm" {
  features {}
}

# Usar valores fijos específicos del despliegue existente
locals {
  suffix = "lsnvfq" # Sufijo específico del servidor existente
  sql_password = "sY7CB!D5$BuzCov3" # Contraseña específica existente
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.resource_group_name}-${local.suffix}"
  location = var.location
}

resource "azurerm_mssql_server" "sqlserver" {
  name                         = "${var.sql_server_name}-${local.suffix}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = var.sql_admin_login
  administrator_login_password = local.sql_password # Usar contraseña fija
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

