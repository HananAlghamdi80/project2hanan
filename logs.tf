#############################################
# 🧠 Log Analytics Workspace (for ACA monitoring)
#############################################
resource "azurerm_log_analytics_workspace" "log" {
  name                = "p2-log-workspace"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

#############################################
# 🪣 Azure Container Registry (for images)
#############################################
resource "azurerm_container_registry" "acr" {
  name                = "p2acrhanan123"       # ⚠️ لازم يكون اسم فريد على مستوى Azure
  resource_group_name = data.azurerm_resource_group.rg.name
  location            = data.azurerm_resource_group.rg.location
  sku                 = "Basic"
  admin_enabled       = true
}
