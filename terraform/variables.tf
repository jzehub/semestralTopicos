variable "resource_group_name" {
  description = "Existing resource group that contains the VNet, ACR, and PostgreSQL server."
  type        = string
  default     = "topicos-2"
}

variable "location" {
  description = "Azure region where the ACI container group will be created."
  type        = string
  default     = "centralus"
}

variable "vnet_name" {
  description = "Existing virtual network name."
  type        = string
  default     = "aci-project"
}

variable "aci_subnet_name" {
  description = "Existing subnet delegated to Azure Container Instances."
  type        = string
  default     = "aci-subnet"
}

variable "container_group_name" {
  description = "Name of the Azure Container Instance container group."
  type        = string
  default     = "taskmanager-backend-aci"
}

variable "container_name" {
  description = "Name of the backend container inside the container group."
  type        = string
  default     = "taskmanager-backend"
}

variable "container_image" {
  description = "Backend container image stored in Azure Container Registry."
  type        = string
  default     = "acicontainer.azurecr.io/taskmanager-backend:latest"
}

variable "acr_server" {
  description = "Azure Container Registry login server."
  type        = string
  default     = "acicontainer.azurecr.io"
}

variable "acr_username" {
  description = "Azure Container Registry username."
  type        = string
  sensitive   = true
}

variable "acr_password" {
  description = "Azure Container Registry password."
  type        = string
  sensitive   = true
}

variable "postgres_host" {
  description = "PostgreSQL Flexible Server host name."
  type        = string
  default     = "aci-project-database.postgres.database.azure.com"
}

variable "postgres_database" {
  description = "PostgreSQL database name."
  type        = string
  default     = "aci-task-manager-bd"
}

variable "postgres_username" {
  description = "PostgreSQL admin/app username."
  type        = string
  default     = "taskadmin"
}

variable "postgres_password" {
  description = "PostgreSQL password."
  type        = string
  sensitive   = true
}
