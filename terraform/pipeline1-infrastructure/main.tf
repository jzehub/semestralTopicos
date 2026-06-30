locals {
  resource_group_name  = coalesce(var.resource_group_name, "rg-${var.project_name}-${var.environment}")
  acr_name             = replace("acr${var.project_name}${var.environment}${random_string.acr_suffix.result}", "-", "")
  normalized_tags      = merge(var.tags, { environment = var.environment })
  frontend_uses_acr = startswith(var.frontend_container_image, "${azurerm_container_registry.main.login_server}/")
  backend_uses_acr = startswith(var.backend_container_image, "${azurerm_container_registry.main.login_server}/")
  database_url = "postgresql://${var.postgres_username}:${var.postgres_password}@${var.postgres_host}:5432/${var.postgres_database}?sslmode=require"
}

resource "random_string" "acr_suffix" {
  length  = 6
  upper   = false
  special = false
}

resource "azurerm_resource_group" "main" {
  name     = local.resource_group_name
  location = var.location
  tags     = local.normalized_tags
}

resource "azurerm_virtual_network" "main" {
  name                = "vnet-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  address_space       = var.vnet_address_space
  tags                = local.normalized_tags
}

resource "azurerm_subnet" "aci" {
  name                 = "snet-aci-${var.environment}"
  resource_group_name  = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes     = var.aci_subnet_address_prefixes

  delegation {
    name = "aci-delegation"

    service_delegation {
      name = "Microsoft.ContainerInstance/containerGroups"
      actions = [
        "Microsoft.Network/virtualNetworks/subnets/action"
      ]
    }
  }
}

resource "azurerm_public_ip" "nat" {
  name                = "pip-nat-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.normalized_tags
}

resource "azurerm_nat_gateway" "main" {
  name                = "nat-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  sku_name            = "Standard"
  tags                = local.normalized_tags
}

resource "azurerm_nat_gateway_public_ip_association" "main" {
  nat_gateway_id       = azurerm_nat_gateway.main.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "aci" {
  subnet_id      = azurerm_subnet.aci.id
  nat_gateway_id = azurerm_nat_gateway.main.id
}

resource "azurerm_container_registry" "main" {
  name                = local.acr_name
  resource_group_name = azurerm_resource_group.main.name
  location            = azurerm_resource_group.main.location
  sku                 = var.acr_sku
  admin_enabled       = false
  tags                = local.normalized_tags
}

resource "azurerm_user_assigned_identity" "aci" {
  name                = "id-aci-${var.project_name}-${var.environment}"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags                = local.normalized_tags
}

resource "azurerm_role_assignment" "aci_acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.aci.principal_id
}


resource "azurerm_subnet" "appgw"{
  name = "snet-appgw-${var.environment}"
  resource_group_name = azurerm_resource_group.main.name
  virtual_network_name = azurerm_virtual_network.main.name
  address_prefixes = var.appgw_subnet_address_prefixes
}

resource "azurerm_public_ip" "appgw"{
  name = var.appgw_public_ip_name
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  allocation_method = "Static"
  sku = "Standard"
  tags = local.normalized_tags
  
}


resource "azurerm_container_group" "frontend"{
  name = var.frontend_container_group_name
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type = "Linux"
  ip_address_type = "Private"
  restart_policy = "Always"
  subnet_ids = [azurerm_subnet.aci.id]
  tags = local.normalized_tags

  identity{
    type = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aci.id]
  }

  dynamic "image_registry_credential"{
    for_each = local.frontend_uses_acr ? [1] : []

    content{
      server = azurerm_container_registry.main.login_server
      user_assigned_identity_id = azurerm_user_assigned_identity.aci.id
    }
  }
  container{
    name = var.frontend_container_name
    image = var.frontend_container_image
    cpu = var.frontend_container_cpu
    memory = var.frontend_container_memory
    ports{
      port = var.frontend_container_port
      protocol = "TCP"
    }
  }

    depends_on = [
      azurerm_role_assignment.aci_acr_pull,
      azurerm_subnet_nat_gateway_association.aci
    ]
  
}


resource "azurerm_container_group" "backend" {
  name                = var.backend_container_group_name
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  os_type             = "Linux"
  ip_address_type     = "Private"
  subnet_ids          = [azurerm_subnet.aci.id]
  restart_policy      = "Always"
  tags                = local.normalized_tags

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.aci.id]
  }

  dynamic "image_registry_credential" {
    for_each = local.backend_uses_acr ? [1] : []

    content {
      server                    = azurerm_container_registry.main.login_server
      user_assigned_identity_id = azurerm_user_assigned_identity.aci.id
    }
  }

  container {
    name   = var.backend_container_name
    image  = var.backend_container_image
    cpu    = var.backend_container_cpu
    memory = var.backend_container_memory

    ports {
      port     = var.backend_container_port
      protocol = "TCP"
    }

    secure_environment_variables = {
      DATABASE_URL = local.database_url
    }
  }

  depends_on = [
    azurerm_role_assignment.aci_acr_pull,
    azurerm_subnet_nat_gateway_association.aci
  ]
}

resource "azurerm_application_gateway" "main"{
  name = var.appgw_gateway_name
  location = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
  tags = local.normalized_tags
    sku {
    name = var.appgw_sku_name
    tier = var.appgw_sku_tier
    capacity = var.appgw_capacity
  }

  gateway_ip_configuration{
    name = "appgw-ip-configuration"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port{
    name = "frontend-port-http"
    port = 80
  }

  frontend_ip_configuration{
    name = "frontend-public-ip"
    public_ip_address_id = azurerm_public_ip.appgw.id
  }

  backend_address_pool{
    name = "frontend-pool"
    ip_addresses = [azurerm_container_group.frontend.ip_address]
  }

  backend_address_pool{
    name = "backend-pool"
    ip_addresses = [azurerm_container_group.backend.ip_address]
  }

  probe{
    name = "frontend-probe"
    protocol = "Http"
    path = "/"
    host = "127.0.0.1"
    interval = 30
    timeout = 30
    unhealthy_threshold = 3
  }

  probe {
    name = "backend-probe"
    protocol = "Http"
    path = "/health"
    host = "127.0.0.1s"
    interval = 30
    timeout = 30
    unhealthy_threshold = 3
  }

  backend_http_settings {
    name = "frontend-http-settings"
    cookie_based_affinity = "Disabled"
    port = var.frontend_container_port
    protocol = "Http"
    request_timeout = 30
    probe_name = "frontend-probe"
  }

  backend_http_settings {
    name = "backend-http-settings"
    cookie_based_affinity = "Disabled"
    port = var.backend_container_port
    protocol = "Http"
    request_timeout = 30
    probe_name = "backend-probe"
  }

  http_listener{
    name = "http-listener"
    frontend_ip_configuration_name = "frontend-public-ip"
    frontend_port_name = "frontend-port-http"
    protocol = "Http"
  }

  url_path_map{
    name = "app-routing"
    default_backend_address_pool_name = "frontend-pool"
    default_backend_http_settings_name = "frontend-http-settings"

    path_rule{
      name = "backend-api"
      paths = ["/tasks*", "/health"]
      backend_address_pool_name = "backend-pool"
      backend_http_settings_name = "backend-http-settings"
    }
  }

  request_routing_rule{
    name = "routing-rule"
    rule_type = "PathBasedRouting"
    http_listener_name = "http-listener"
    url_path_map_name = "app-routing"
    priority = 100
  }

  depends_on = [
    azurerm_container_group.frontend,
    azurerm_container_group.backend
  ]
}
