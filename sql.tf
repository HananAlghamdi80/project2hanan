#############################################
# 🧠 Azure SQL Server + Database (Private)
#############################################

resource "azurerm_mssql_server" "sql" {
  name                          = "p2-sqlserver-hanan3"   # ✅ اسم فريد
  resource_group_name           = data.azurerm_resource_group.rg.name
  location                      = "eastus2"      # 🇸🇪 المنطقة الجديدة
  version                       = "12.0"
  administrator_login           = "sqladminuser"
  administrator_login_password  = "Hh123@123"
  public_network_access_enabled = false
}

#############################################
# 🗄️ Azure SQL Database
#############################################

resource "azurerm_mssql_database" "sqldb" {
  name      = "hanandb"
  server_id = azurerm_mssql_server.sql.id
  sku_name  = "S0"
}

#############################################
# 🔒 Private Endpoint for SQL
#############################################

resource "azurerm_private_endpoint" "sql_pe" {
  name                = "p2-sql-pe"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  subnet_id           = azurerm_subnet.sql.id

  private_service_connection {
    name                           = "p2-sql-connection"
    private_connection_resource_id = azurerm_mssql_server.sql.id
    subresource_names              = ["sqlServer"]
    is_manual_connection           = false
  }
}

#############################################
# 🌐 Private DNS Zone for SQL Server
#############################################

# DNS Zone
resource "azurerm_private_dns_zone" "sql_dns" {
  name                = "privatelink.database.windows.net"
  resource_group_name = data.azurerm_resource_group.rg.name
}

# Link DNS Zone to VNet
resource "azurerm_private_dns_zone_virtual_network_link" "sql_dns_link" {
  name                  = "p2-sql-dns-link"
  resource_group_name   = data.azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.sql_dns.name
  virtual_network_id    = azurerm_virtual_network.vnet.id
}

# DNS A Record for SQL
resource "azurerm_private_dns_a_record" "sql_record" {
  name                = azurerm_mssql_server.sql.name
  zone_name           = azurerm_private_dns_zone.sql_dns.name
  resource_group_name = data.azurerm_resource_group.rg.name
  ttl                 = 300
  records             = [azurerm_private_endpoint.sql_pe.private_service_connection[0].private_ip_address]
}

#############################################
# 🧾 Outputs (لتأكيد النتائج بعد الإنشاء)
#############################################

output "sql_server_name" {
  description = "اسم خادم SQL Server"
  value       = azurerm_mssql_server.sql.name
}

output "sql_server_fqdn" {
  description = "عنوان الخادم (FQDN)"
  value       = azurerm_mssql_server.sql.fully_qualified_domain_name
}

output "sql_private_ip" {
  description = "العنوان الداخلي لقاعدة البيانات"
  value       = azurerm_private_endpoint.sql_pe.private_service_connection[0].private_ip_address
}
