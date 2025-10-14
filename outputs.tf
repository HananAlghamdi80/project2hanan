#########################################
# 📤 Outputs (Fixed)
#########################################

# Resource Group Info
output "resource_group_name" {
  value = data.azurerm_resource_group.rg.name
}

output "resource_group_location" {
  value = data.azurerm_resource_group.rg.location
}

# Network Info
output "vnet_name" {
  value = azurerm_virtual_network.vnet.name
}

output "appgw_subnet_id" {
  value = azurerm_subnet.appgw.id
}

output "containerapps_subnet_id" {
  value = azurerm_subnet.containerapps.id
}

output "sql_subnet_id" {
  value = azurerm_subnet.sql.id
}
