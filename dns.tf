#############################################
# 🌐 Private DNS Zone for Container Apps
#############################################
resource "azurerm_private_dns_zone" "aca_dns" {
  name                = "private.azurecontainerapps.io"
  resource_group_name = data.azurerm_resource_group.rg.name
}

#############################################
# 🔗 Link DNS Zone to your VNet
#############################################
resource "azurerm_private_dns_zone_virtual_network_link" "aca_dns_link" {
  name                  = "aca-dns-link"
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.aca_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}
