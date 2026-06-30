output "container_group_name" {
  description = "Created ACI container group name."
  value       = azurerm_container_group.backend.name
}

output "container_group_private_ip" {
  description = "Private IP address assigned to the ACI container group."
  value       = azurerm_container_group.backend.ip_address
}

output "backend_health_url_private" {
  description = "Private health endpoint for the backend. This is reachable only from inside the VNet."
  value       = "http://${azurerm_container_group.backend.ip_address}:5000/health"
}
