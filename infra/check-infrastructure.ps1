# Script para verificar si la infraestructura ya existe
# Si existe, configura Terraform para usarla

$resourceGroupName = "rg-upt-tech-analysis-lsnvfq"
$sqlServerName = "sql-upt-tech-analysis-server-lsnvfq"
$storageAccountName = "stterraformstatelsnvfq"

Write-Host "=== Verificando infraestructura existente ===" -ForegroundColor Green

# Verificar si Azure CLI está instalado y logueado
try {
    $account = az account show --query "name" -o tsv 2>$null
    if (-not $account) {
        Write-Host "Iniciando sesión en Azure..." -ForegroundColor Yellow
        az login
    } else {
        Write-Host "Azure CLI conectado: $account ✓" -ForegroundColor Green
    }
}
catch {
    Write-Host "ERROR: Azure CLI no disponible. Ejecuta .\install-azure-cli.ps1" -ForegroundColor Red
    exit 1
}

# Verificar si el servidor SQL ya existe
$sqlExists = az sql server show --name $sqlServerName --resource-group $resourceGroupName 2>$null
if ($sqlExists) {
    Write-Host "SQL Server encontrado: $sqlServerName ✓" -ForegroundColor Green
    
    # Verificar si el backend storage existe
    $storageExists = az storage account show --name $storageAccountName --resource-group $resourceGroupName 2>$null
    if ($storageExists) {
        Write-Host "Storage Account encontrado: $storageAccountName ✓" -ForegroundColor Green
        Write-Host ""
        Write-Host "=== INFRAESTRUCTURA YA EXISTE ===" -ForegroundColor Yellow
        Write-Host "Puedes hacer push directamente al repositorio" -ForegroundColor Green
        Write-Host "Los workflows automáticos funcionarán correctamente" -ForegroundColor Green
    } else {
        Write-Host "Storage Account no encontrado. Ejecutando configuración..." -ForegroundColor Yellow
        .\setup-backend.ps1
    }
} else {
    Write-Host "SQL Server no encontrado. Necesitas desplegar la infraestructura primero." -ForegroundColor Yellow
    Write-Host "Ejecuta: .\setup-backend.ps1 y luego terraform apply" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Configuración actual:" -ForegroundColor Cyan
Write-Host "DB_SERVER: sql-upt-tech-analysis-server-lsnvfq.database.windows.net" -ForegroundColor White
Write-Host "DB_DATABASE: db-upt-tech-analysis" -ForegroundColor White
Write-Host "DB_USERNAME: dbadmin885" -ForegroundColor White
Write-Host "DB_PASSWORD: sY7CB!D5$BuzCov3" -ForegroundColor White
