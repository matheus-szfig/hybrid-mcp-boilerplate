locals {
  prefix = "${var.app_name}-${var.environment}"
}

# ── Resource Group ────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "main" {
  name     = "rg-${local.prefix}"
  location = var.location
}

# ── App Service Plan ──────────────────────────────────────────────────────────
# Basic B1 is the minimum tier that supports always_on = true.

resource "azurerm_service_plan" "main" {
  name                = "asp-${local.prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  os_type             = "Linux"
  sku_name            = "B1"
}

# ── Linux Web App ─────────────────────────────────────────────────────────────

resource "azurerm_linux_web_app" "main" {
  name                = "app-${local.prefix}"
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  service_plan_id     = azurerm_service_plan.main.id

  site_config {
    always_on = true

    application_stack {
      python_version = "3.12"
    }

    app_command_line = "uvicorn main:app --host 0.0.0.0 --port 8000"
  }

  app_settings = {
    # App
    APP_NAME = var.app_name

    # Database — maps to _Database BaseSettings with DATABASE_ prefix
    DATABASE_HOST     = azurerm_postgresql_flexible_server.main.fqdn
    DATABASE_PORT     = "5432"
    DATABASE_NAME     = var.db_name
    DATABASE_USER     = "${var.db_user}@${azurerm_postgresql_flexible_server.main.name}"
    DATABASE_PASSWORD = var.db_password

    # CORS — maps to _Cors BaseSettings with CORS_ prefix
    CORS_ALLOWED_ORIGINS = jsonencode(var.cors_allowed_origins)
    CORS_ALLOWED_METHODS = jsonencode(var.cors_allowed_methods)
    CORS_ALLOWED_HEADERS = jsonencode(var.cors_allowed_headers)

    # Disable .env file loading in production (env vars come from App Settings)
    PYTHONDONTWRITEBYTECODE = "1"
    SCM_DO_BUILD_DURING_DEPLOYMENT = "true"
  }
}

# ── PostgreSQL Flexible Server ────────────────────────────────────────────────
# Burstable B1ms is the cheapest available SKU (~$15/month).
# No HA and no geo-redundant backup to minimise cost.

resource "azurerm_postgresql_flexible_server" "main" {
  name                   = "psql-${local.prefix}"
  resource_group_name    = azurerm_resource_group.main.name
  location               = azurerm_resource_group.main.location
  version                = "16"
  administrator_login    = var.db_user
  administrator_password = var.db_password

  sku_name   = "B_Standard_B1ms"
  storage_mb = 32768  # 32 GB — minimum

  backup_retention_days        = 7
  geo_redundant_backup_enabled = false

  high_availability {
    mode = "Disabled"
  }
}

resource "azurerm_postgresql_flexible_server_database" "main" {
  name      = var.db_name
  server_id = azurerm_postgresql_flexible_server.main.id
  charset   = "UTF8"
  collation = "en_US.utf8"
}

# Allow all Azure services to reach the database.
# App Service outbound IPs can change, so this rule is the simplest approach
# without requiring VNet integration (which needs Standard tier).
resource "azurerm_postgresql_flexible_server_firewall_rule" "allow_azure_services" {
  name             = "allow-azure-services"
  server_id        = azurerm_postgresql_flexible_server.main.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}
