#########################################
# 📦 Existing Resource Group
#########################################
data "azurerm_resource_group" "rg" {
  name = "p2-rg"
}

#########################################
# 🌐 Virtual Network
#########################################
resource "azurerm_virtual_network" "vnet" {
  name                = "hanan-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
}

#########################################
# 🕹️ Subnets (Simplified for Container Apps)
# 1. snet-appgw → Application Gateway (Public)
# 2. snet-containerapps → Both frontend & backend (Private)
# 3. snet-sql → Database private endpoint
#########################################

# Application Gateway subnet (public entry)
resource "azurerm_subnet" "appgw" {
  name                 = "snet-appgw"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Container Apps subnet (private)
resource "azurerm_subnet" "containerapps" {
  name                 = "snet-containerapps"
  resource_group_name  = data.azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.0.2.0/23"] # ✅ required size for ACA
}

# SQL subnet (for Private Endpoint only)
resource "azurerm_subnet" "sql" {
  name                              = "snet-sql"
  resource_group_name               = data.azurerm_resource_group.rg.name
  virtual_network_name              = azurerm_virtual_network.vnet.name
  address_prefixes                  = ["10.0.4.0/24"]
  private_endpoint_network_policies = "Disabled"
}
