resource "azurerm_public_ip" "app_gateway" {
  name                = "${var.environment_prefix}-appgw-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

resource "azurerm_application_gateway" "main" {
  name                = "${var.environment_prefix}-appgw"
  location            = var.location
  resource_group_name = var.resource_group_name
  tags                = var.tags

  sku {
    name     = var.app_gateway_sku
    tier     = replace(var.app_gateway_sku, "_v2", "")
    capacity = 2
  }

  gateway_ip_configuration {
    name      = "gateway_ip_config"
    subnet_id = var.app_gateway_subnet_id
  }

  frontend_port {
    name = "http"
    port = 80
  }

  frontend_port {
    name = "https"
    port = 443
  }

  frontend_ip_configuration {
    name                 = "appgw_frontend_ip_config"
    public_ip_address_id = azurerm_public_ip.app_gateway.id
  }

  backend_address_pool {
    name = "default_backend_pool"
  }

  backend_http_settings {
    name                  = "default_http_settings"
    cookie_based_affinity = "Disabled"
    port                  = 80
    protocol              = "Http"
    request_timeout       = 20
    host_name             = ""
  }

  http_listener {
    name                           = "default_http_listener"
    frontend_ip_configuration_name = "appgw_frontend_ip_config"
    frontend_port_name             = "http"
    protocol                       = "Http"
    host_name                      = ""
  }

  request_routing_rule {
    name                       = "default_routing_rule"
    rule_type                  = "Basic"
    http_listener_name         = "default_http_listener"
    backend_address_pool_name  = "default_backend_pool"
    backend_http_settings_name = "default_http_settings"
    priority                   = 100
  }

  # Enable WAF
  waf_configuration {
    enabled          = true
    firewall_mode    = "Prevention"
    rule_set_type    = "OWASP"
    rule_set_version = "3.1"
  }

  # Auto-scaling
  autoscale_configuration {
    min_capacity = 2
    max_capacity = 10
  }
}

# Backend pool for AKS
resource "azurerm_application_gateway_backend_pool" "aks" {
  name                        = "aks_backend_pool"
  application_gateway_id      = azurerm_application_gateway.main.id
  ip_address_list             = []  # Will be populated with AKS node IPs
}

# Health probe
resource "azurerm_application_gateway_probe" "aks" {
  name                = "aks_health_probe"
  application_gateway_id = azurerm_application_gateway.main.id
  protocol            = "Http"
  path                = "/healthz"
  host                = "localhost"
  interval            = 30
  timeout             = 3
  unhealthy_threshold = 3
  pick_host_name_from_backend_http_settings = true
}

# SSL Policy
resource "azurerm_application_gateway_ssl_policy" "main" {
  application_gateway_id = azurerm_application_gateway.main.id
  policy_type            = "Predefined"
  policy_name            = "AppGwSslPolicy20170401"
}
