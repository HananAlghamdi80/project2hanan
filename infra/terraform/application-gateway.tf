#################################
# Public IP for Application Gateway
#################################
resource "azurerm_public_ip" "appgw_pip" {
  name                = "p2-appgw-pip"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

#################################
# Web Application Firewall Policy
#################################
resource "azurerm_web_application_firewall_policy" "waf_policy" {
  name                = "p2-waf-policy"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  policy_settings {
    enabled            = true
    mode               = "Prevention"
    request_body_check = true
  }

  managed_rules {
    managed_rule_set {
      type    = "OWASP"
      version = "3.2"
    }
  }
}

#################################
# Application Gateway (WAF_v2)
#################################
resource "azurerm_application_gateway" "appgw" {
  name                = "p2-appgw"
  location            = data.azurerm_resource_group.rg.location
  resource_group_name = data.azurerm_resource_group.rg.name

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 2
  }

  ssl_policy {
    policy_type = "Predefined"
    policy_name = "AppGwSslPolicy20220101"
  }

  firewall_policy_id = azurerm_web_application_firewall_policy.waf_policy.id

  gateway_ip_configuration {
    name      = "appgw-ipcfg"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = "httpPort"
    port = 80
  }

  frontend_ip_configuration {
    name                 = "appgwFrontendIP"
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  #################################
  # Health Probes (updated)
  #################################
  probe {
    name                                      = "frontend-probe"
    protocol                                  = "Http"
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 10
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  probe {
    name                                      = "backend-probe"
    protocol                                  = "Http"
    path                                      = "/actuator/health"
    interval                                  = 30
    timeout                                   = 10
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true
  }

  #################################
  # HTTP Settings
  #################################
  backend_http_settings {
    name                  = "frontendHttpSettings"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
    cookie_based_affinity = "Disabled"
    probe_name            = "frontend-probe"
    host_name             = "p2-frontend.politemeadow-35232c10.eastus.azurecontainerapps.io"
  }

  backend_http_settings {
    name                  = "backendHttpSettings"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 30
    cookie_based_affinity = "Disabled"
    probe_name            = "backend-probe"
    host_name             = "p2-backend.politemeadow-35232c10.eastus.azurecontainerapps.io"
  }

  #################################
  # Backend Pools
  #################################
  backend_address_pool {
    name  = "frontendPool"
    fqdns = ["p2-frontend.politemeadow-35232c10.eastus.azurecontainerapps.io"]
  }

  backend_address_pool {
    name  = "backendPool"
    fqdns = ["p2-backend.politemeadow-35232c10.eastus.azurecontainerapps.io"]
    # fqdns = ["p2.backend.${container_apps_environment_default_domain_name}"]
  }

  #################################
  # Listener
  #################################
  http_listener {
    name                           = "mainListener"
    frontend_ip_configuration_name = "appgwFrontendIP"
    frontend_port_name             = "httpPort"
    protocol                       = "Http"
  }

  #################################
  # Path-based Routing
  #################################
  url_path_map {
    name                               = "pathMap1"
    default_backend_address_pool_name  = "frontendPool"
    default_backend_http_settings_name = "frontendHttpSettings"

    path_rule {
      name                       = "backendPathRule"
      paths                      = ["/api/*"]
      backend_address_pool_name  = "backendPool"
      backend_http_settings_name = "backendHttpSettings"
    }
  }

  request_routing_rule {
    name               = "rule1"
    rule_type          = "PathBasedRouting"
    http_listener_name = "mainListener"
    url_path_map_name  = "pathMap1"
    priority           = 100
  }

  depends_on = [
    azurerm_container_app.frontend,
    azurerm_container_app.backend
  ]
}
