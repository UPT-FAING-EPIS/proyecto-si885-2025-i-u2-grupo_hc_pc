terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~>3.0"
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

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_storage_account" "storage" {
  name                     = "${var.storage_account_name}${random_string.suffix.result}"
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_table" "table" {
  name                 = var.storage_table_name
  storage_account_name = azurerm_storage_account.storage.name
}
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
