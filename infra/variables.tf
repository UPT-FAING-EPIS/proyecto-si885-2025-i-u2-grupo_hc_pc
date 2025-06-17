variable "location" {
  description = "The Azure region where resources will be created."
  type        = string
  default     = "West US 2"
}

variable "resource_group_name" {
  description = "The name of the resource group."
  type        = string
  default     = "rg-upt-tech-analysis"
}

variable "storage_account_name" {
  description = "The base name for the Azure Storage Account. Must be globally unique."
  type        = string
  default     = "stupttechanalysis"
}

variable "storage_table_name" {
  description = "The name of the Azure Storage Table."
  type        = string
  default     = "tecnologias"
}
