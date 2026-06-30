output "resource_group_name" {
  description = "Resource group created by Terraform."
  value       = azurerm_resource_group.main.name
}

output "location" {
  description = "Azure region used for the infrastructure."
  value       = azurerm_resource_group.main.location
}

output "vnet_name" {
  description = "Virtual network name."
  value       = azurerm_virtual_network.main.name
}

output "aci_subnet_name" {
  description = "Subnet delegated to Azure Container Instances."
  value       = azurerm_subnet.aci.name
}

output "aci_subnet_id" {
  description = "Subnet ID used by the Azure Container Instance."
  value       = azurerm_subnet.aci.id
}

output "acr_name" {
  description = "Azure Container Registry name."
  value       = azurerm_container_registry.main.name
}

output "acr_login_server" {
  description = "Azure Container Registry login server."
  value       = azurerm_container_registry.main.login_server
}

output "aci_identity_client_id" {
  description = "Client ID of the user-assigned identity attached to ACI."
  value       = azurerm_user_assigned_identity.aci.client_id
}

output "frontend_container_group_name" {
  description = "Frontend Azure Container Instance container group name."
  value       = azurerm_container_group.frontend.name
}

output "frontend_container_private_ip" {
  description = "Private IP address assigned to the frontend ACI."
  value       = azurerm_container_group.frontend.ip_address
}

output "backend_container_group_name" {
  description = "Backend Azure Container Instance container group name."
  value       = azurerm_container_group.backend.name
}

output "backend_container_private_ip" {
  description = "Private IP address assigned to the backend ACI."
  value       = azurerm_container_group.backend.ip_address
}

output "frontend_private_endpoint" {
  description = "Private endpoint for the frontend container."
  value       = "http://${azurerm_container_group.frontend.ip_address}:${var.frontend_container_port}"
}

output "backend_private_endpoint" {
  description = "Private endpoint for the backend container."
  value       = "http://${azurerm_container_group.backend.ip_address}:${var.backend_container_port}"
}

output "application_gateway_public_ip" {
  description = "Public IP address of the Application Gateway."
  value       = azurerm_public_ip.appgw.ip_address
}

output "application_gateway_url" {
  description = "Public URL of the Application Gateway."
  value       = "http://${azurerm_public_ip.appgw.ip_address}"
}

output "nat_gateway_public_ip" {
  description = "Public IP used by the NAT gateway for outbound traffic from the ACI subnet."
  value       = azurerm_public_ip.nat.ip_address
}
