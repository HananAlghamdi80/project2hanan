#############################################
# 🌍 Container Apps Environment (VNet integrated)
#############################################
resource "azurerm_container_app_environment" "cae" {
  name                = "p2-cae"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  infrastructure_subnet_id       = azurerm_subnet.containerapps.id
  internal_load_balancer_enabled = true
  log_analytics_workspace_id     = azurerm_log_analytics_workspace.log.id
}

#############################################
# 🧱 Backend Container App (Private)
#############################################
resource "azurerm_container_app" "backend" {
  name                         = "p2-backend"
  resource_group_name          = data.azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.cae.id
  revision_mode                = "Single"

  template {
    container {
      name   = "backend"
      image  = "p2acrhanan123.azurecr.io/p2-backend:latest"
      cpu    = 0.5
      memory = "1Gi"

      #############################################
      # ✅ متغيرات البيئة للاتصال بقاعدة البيانات
      #############################################
      env {
        name  = "DB_URL"
        value = "jdbc:sqlserver://p2-sqlserver-hanan.database.windows.net:1433;database=hanandb;encrypt=true;trustServerCertificate=false;loginTimeout=30;"
      }
      env {
        name  = "DB_USER"
        value = "sqladminuser"
      }
      env {
        name  = "DB_PASS"
        value = "Hh123@123"
      }

      env {
        name  = "PORT"
        value = "8080"
      }
    }
  }

  ingress {
    external_enabled = false      # Private backend
    target_port      = 8080
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.acr.admin_password
  }
}

#############################################
# 💻 Frontend Container App (Public for testing)
#############################################
resource "azurerm_container_app" "frontend" {
  name                         = "p2-frontend"
  resource_group_name          = data.azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.cae.id
  revision_mode                = "Single"

  template {
    container {
      name   = "frontend"
      image  = "p2acrhanan123.azurecr.io/p2-frontend:latest"
      cpu    = 0.5
      memory = "1Gi"

      #############################################
      # ✅ الرابط الداخلي الصحيح للباك اند داخل البيئة الخاصة
      #############################################
      env {
        name  = "VITE_API_URL"
        value = "http://p2-backend.internal.p2-cae.eastus.azurecontainerapps.io:8080"
      }

      env {
        name  = "PORT"
        value = "80"
      }
    }
  }

  ingress {
    external_enabled = true      # ✅ Public for AppGW access
    target_port      = 80
    transport        = "auto"

    traffic_weight {
      latest_revision = true
      percentage      = 100
    }
  }

  registry {
    server               = azurerm_container_registry.acr.login_server
    username             = azurerm_container_registry.acr.admin_username
    password_secret_name = "acr-password"
  }

  secret {
    name  = "acr-password"
    value = azurerm_container_registry.acr.admin_password
  }
}
