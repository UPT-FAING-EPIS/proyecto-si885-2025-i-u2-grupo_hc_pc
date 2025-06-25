# Infraestructura Azure - UPT Tech Analysis

⚠️ **IMPORTANTE**: Infraestructura ya configurada con credenciales específicas

## 🚀 **Verificación Rápida** (Ejecutar primero)

```powershell
cd C:\Users\HP\Documents\Serie\proyecto-si885-2025-i-u2-grupo_hc_pc\infra
.\check-infrastructure.ps1
```

Este script verificará si tu infraestructura ya existe y te dirá qué hacer.

## ⚙️ Solo si la infraestructura NO existe

### Paso 1: Instalar Azure CLI (si no lo tienes)

**Ejecuta como administrador en PowerShell:**
```powershell
# Navega al directorio infra
cd infra

# Instala Azure CLI
.\install-azure-cli.ps1

# Cierra y abre PowerShell nuevamente
```

### Paso 2: Configurar Backend de Terraform

**En PowerShell (normal, no como admin):**
```powershell
# Asegúrate de estar en el directorio correcto
cd C:\Users\HP\Documents\Serie\proyecto-si885-2025-i-u2-grupo_hc_pc\infra

# Ejecuta el script (nota el .\ al inicio)
.\setup-backend.ps1
```

**En Linux/Mac:**
```bash
# Asegúrate de estar logueado en Azure
az login

# Navega al directorio infra
cd infra

# Da permisos y ejecuta el script
chmod +x setup-backend.sh
./setup-backend.sh
```

### Paso 2: Comentar el Backend Temporalmente

Antes del primer `terraform init`, comenta estas líneas en `main.tf`:
```hcl
# backend "azurerm" {
#   resource_group_name  = "rg-terraform-state"
#   storage_account_name = "stterraformstatehcpc"
#   container_name      = "tfstate"
#   key                 = "upt-tech-analysis.terraform.tfstate"
# }
```

### Paso 3: Primer Despliegue Local

```powershell
# En el directorio infra
cd C:\Users\HP\Documents\Serie\proyecto-si885-2025-i-u2-grupo_hc_pc\infra

# Inicializar Terraform (sin backend)
terraform init

# Planificar despliegue
terraform plan

# Aplicar infraestructura
terraform apply
```

### Paso 4: Migrar al Backend Remoto

```powershell
# Descomentar el backend en main.tf (quitar los # del bloque backend)
# Luego ejecutar:
terraform init -migrate-state
```

### Paso 5: Push al Repositorio

1. Descomenta las líneas del backend en `main.tf`
2. Commit y push al repositorio
3. ¡Ya puedes usar los workflows automáticos!

## 🎯 **Orden de Ejecución Simplificado**

```
1. .\check-infrastructure.ps1  (verificar estado actual)
2. Si todo existe ✓ → Push directo al repo
3. Si falta algo → Seguir pasos de configuración
```

✅ **Con las credenciales específicas, es probable que puedas hacer push directamente**

## Arquitectura

La infraestructura incluye:

- **Resource Group**: `rg-upt-tech-analysis-lsnvfq`
- **SQL Server**: `sql-upt-tech-analysis-server-lsnvfq`
- **SQL Database**: `db-upt-tech-analysis`
- **Firewall Rules**: Para Power BI y servicios de Azure

**Credenciales específicas:**
- **Server FQDN**: `sql-upt-tech-analysis-server-lsnvfq.database.windows.net`
- **Username**: `dbadmin885`
- **Password**: `sY7CB!D5$BuzCov3`

## Workflows

### 1. `infrastructure-deploy.yml`
- Se ejecuta cuando hay cambios en `/infra/`
- Despliega/actualiza la infraestructura
- Ejecutar manualmente para despliegues controlados

### 2. `etl_pipeline.yml`
- Se ejecuta semanalmente (lunes 3 AM UTC)
- Verifica infraestructura existente
- Ejecuta el script ETL de datos
- **NO crea nueva infraestructura**

### 3. `cost-analysis.yml`
- Analiza costos en Pull Requests
- Usa Infracost para estimaciones

## Características Principales

✅ **Estado Persistente**: Terraform usa backend remoto en Azure Storage
✅ **Recursos Estables**: Nombres fijos (no aleatorios) para mantener la misma DB
✅ **Contraseña Estable**: No se regenera en cada apply
✅ **ETL Optimizado**: Solo verifica infraestructura, no la recrea

## Variables de Configuración

- `location`: "West US 2"
- `resource_group_name`: "rg-upt-tech-analysis"
- `sql_server_name`: "sql-upt-tech-analysis-server"
- `sql_database_name`: "db-upt-tech-analysis"
- `sql_admin_login`: "dbadmin885"

## Outputs

- `sql_server_fqdn`: FQDN del servidor SQL
- `sql_database_name`: Nombre de la base de datos
- `sql_admin_login`: Usuario administrador
- `sql_admin_password`: Contraseña (sensitive)

## Notas Importantes

1. La infraestructura se crea **una sola vez**
2. El ETL se ejecuta **sin recrear recursos**
3. Los datos se **sobreescriben** en la misma base de datos
4. El estado se mantiene en Azure Storage para consistencia
