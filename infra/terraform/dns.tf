#############################################
# 🌍 Private DNS Zone for Container Apps Environment
#############################################
resource "azurerm_private_dns_zone" "aca_dns" {
  name                = "politemeadow-35232c10.eastus.azurecontainerapps.io"
  resource_group_name = data.azurerm_resource_group.rg.name
}

#############################################
# 🔗 Link DNS Zone to your VNet
#############################################
resource "azurerm_private_dns_zone_virtual_network_link" "aca_dns_link" {
  name                  = "p2-cae-dns-link"
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.aca_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
  registration_enabled  = false
}

#############################################
# ⭐ Wildcard Record for internal apps (*.internal)
#############################################
resource "azurerm_private_dns_a_record" "aca_wildcard" {
  name                = "*"
  zone_name           = azurerm_private_dns_zone.aca_dns.name
  resource_group_name = data.azurerm_resource_group.rg.name
  records             = ["10.0.2.62"] # ← هذا هو IP البيئة الداخلي
  ttl                 = 300
}
