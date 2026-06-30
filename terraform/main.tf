data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.main.name
}

data "azurerm_subnet" "aci" {
  name                 = var.aci_subnet_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}

locals {
  database_url = "postgresql://${var.postgres_username}:${var.postgres_password}@${var.postgres_host}:5432/${var.postgres_database}?sslmode=require"
}

resource "azurerm_container_group" "backend" {
  name                = var.container_group_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  os_type             = "Linux"
  ip_address_type     = "Private"
  subnet_ids          = [data.azurerm_subnet.aci.id]

  image_registry_credential {
    server   = var.acr_server
    username = var.acr_username
    password = var.acr_password
  }

  container {
    name   = var.container_name
    image  = var.container_image
    cpu    = 1
    memory = 1.5

    ports {
      port     = 5000
      protocol = "TCP"
    }

    secure_environment_variables = {
      DATABASE_URL = local.database_url
    }
  }
}
