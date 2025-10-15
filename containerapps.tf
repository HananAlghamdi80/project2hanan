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
# 🧱 Backend Container App (Private - internal ILB)
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
      env {
        name  = "CORS_ALLOWED_ORIGINS"
        value = "http://20.120.114.139"
      }

      env {
        name  = "DB_DRIVER"
        value = "com.microsoft.sqlserver.jdbc.SQLServerDriver"
      }

      env {
        name  = "DB_HOST"
        value = "p2-sqlserver-hanan3.database.windows.net"
      }

      env {
        name  = "DB_NAME"
        value = "hanandb"
      }
      env {
        name  = "DB_PASSWORD"
        value = "Hh123@123"
      }

      env {
        name  = "DB_PORT"
        value = "1433"
      }

      env {
        name  = "DB_USERNAME"
        value = "sqladminuser"
      }

      env {
        name  = "SERVER_PORT"
        value = "8080"
      }

      env {
        name  = "SPRING_PROFILES_ACTIVE"
        value = "azure"
      }
      # ✅ Updated DB connection to the new SQL Server

    }
  }

  ingress {
    external_enabled = true
    target_port      = 8080
    transport        = "http"
    allow_insecure_connections = true


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
# 💻 Frontend Container App (Public for AppGW)
#############################################
resource "azurerm_container_app" "frontend" {
  name                         = "p2-frontend"
  resource_group_name          = data.azurerm_resource_group.rg.name
  container_app_environment_id = azurerm_container_app_environment.cae.id
  revision_mode                = "Single"

  template {
    container {
      name   = "frontend"
      image  = "p2acrhanan123.azurecr.io/p2-frontend:2.0.0"
      cpu    = 0.5
      memory = "1Gi"

      # 🧭 API endpoint points to backend internal domain (ILB)
      env {
        name  = "VITE_API_URL"
        value = "http://20.120.114.139"
      }
      env {
        name  = "SERVER_PORT"
        value = "80"
      }
      

    }
  }

  ingress {
    external_enabled = true
    target_port      = 80
    transport        = "http"
    allow_insecure_connections = true

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
