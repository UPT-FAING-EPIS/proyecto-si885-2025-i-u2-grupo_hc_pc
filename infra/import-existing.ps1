# Script para importar recursos existentes a Terraform
# Ejecutar SOLO si ya tienes los recursos desplegados en Azure

Write-Host "=== Importando recursos existentes ===" -ForegroundColor Green

# Verificar si Azure CLI está disponible
try {
    az account show > $null
    Write-Host "Azure CLI conectado ✓" -ForegroundColor Green
}
catch {
    Write-Host "ERROR: Ejecuta 'az login' primero" -ForegroundColor Red
    exit 1
}

# Recursos a importar
$resourceGroupName = "rg-upt-tech-analysis-lsnvfq"
$sqlServerName = "sql-upt-tech-analysis-server-lsnvfq"
$databaseName = "db-upt-tech-analysis"

Write-Host "Inicializando Terraform..." -ForegroundColor Yellow
terraform init

Write-Host "Importando Resource Group..." -ForegroundColor Yellow
$rgId = "/subscriptions/77cd7a47-822a-4598-86ae-5e51840f4867/resourceGroups/$resourceGroupName"
terraform import azurerm_resource_group.rg $rgId

Write-Host "Importando SQL Server..." -ForegroundColor Yellow
$sqlId = "/subscriptions/77cd7a47-822a-4598-86ae-5e51840f4867/resourceGroups/$resourceGroupName/providers/Microsoft.Sql/servers/$sqlServerName"
terraform import azurerm_mssql_server.sqlserver $sqlId

Write-Host "Importando SQL Database..." -ForegroundColor Yellow
$dbId = "/subscriptions/77cd7a47-822a-4598-86ae-5e51840f4867/resourceGroups/$resourceGroupName/providers/Microsoft.Sql/servers/$sqlServerName/databases/$databaseName"
terraform import azurerm_mssql_database.db $dbId

Write-Host ""
Write-Host "=== Importación completada ===" -ForegroundColor Green
Write-Host "Ahora ejecuta: terraform plan" -ForegroundColor Yellow
