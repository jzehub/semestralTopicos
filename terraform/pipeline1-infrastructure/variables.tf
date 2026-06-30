variable "project_name" {
  description = "nombre del proyecto donde se desplegara la infraestructura"
  type        = string
  default     = "taskmanager"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.project_name))
    error_message = "project_name must be 3-20 characters and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "environment" {
  description = "nombre del ambiente donde se desplegara la infraestructura (dev, staging, prod)"
  type        = string
  default     = "dev"

  validation {
    condition     = can(regex("^[a-z0-9-]{2,12}$", var.environment))
    error_message = "environment must be 2-12 characters and contain only lowercase letters, numbers, and hyphens."
  }
}

variable "location" {
  description = "Region de Azure donde se crearán los recursos."
  type        = string
  default     = "centralus"
}

variable "resource_group_name" {
  description = "Nombre del grupo de recursos donde se desplegará la infraestructura."
  type        = string
  default     = "topicos-semestral"
}

variable "vnet_address_space" {
  description = "Espacio de direcciones para la red virtual."
  type        = list(string)
  default     = ["10.30.0.0/16"]
}

variable "aci_subnet_address_prefixes" {
  description = "Prefijo de direcciones para la subred delegada a Azure Container Instances."
  type        = list(string)
  default     = ["10.30.1.0/24"]
}

variable "acr_sku" {
  description = "SKU para el Azure Container Registry creado por Pipeline 1."
  type        = string
  default     = "Basic"

  validation {
    condition     = contains(["Basic", "Standard", "Premium"], var.acr_sku)
    error_message = "acr_sku must be Basic, Standard, or Premium."
  }
}

#Application Gateway variables

variable "appgw_subnet_address_prefixes"{
  description = "Prefijo de direcciones para la subred delegada a Azure Application Gateway."
  type       = list(string)
  default     = ["10.30.2.0/24"]
}

variable "appgw_gateway_name" {
  description = "Nombre del Application Gateway que se creará."
  type        = string
  default     = "appgw-taskmanager-dev"
}

variable "appgw_public_ip_name" {
  description = "Nombre de la IP pública asociada al Application Gateway."
  type        = string
  default     = "pip-appgw-taskmanager-dev"
}

variable "appgw_sku_name" {
  description = "SKU del Application Gateway."
  type        = string
  default     = "Standard_v2"
}

variable "appgw_sku_tier" {
  description = "Tier del Application Gateway."
  type        = string
  default     = "Standard_v2"
}

variable "appgw_capacity" {
  description = "Cantidad de instancias del Application Gateway."
  type        = number
  default     = 1
}

# Frontend variables for ACI

variable "frontend_container_group_name" {
  description = "Nombre del grupo de contenedores de ACI para alojar el frontend."
  type        = string
  default     = "frontend-aci"
}

variable "frontend_container_name"{
  description = "Nombre del contenedor de ACI para alojar el frontend"
  type = string
  default = "frontend-container"
}

variable "frontend_container_image"{
  description = "Imagen de container usada por ACI para alojar el frontend, por ahora es una imagen pública de ejemplo, pero en pipelines posteriores se usará una imagen personalizada almacenada en un ACR."
  type        = string
  default     = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
}

variable "frontend_container_port"{
  description = "Puerto TCP expuesto por el contenedor del frontend"
  type = number
  default = 80
}

variable "frontend_container_cpu"{
  description = "Núcleos de CPU asignados al contenedor del frontend"
  type = number
  default = 1
}

variable "frontend_container_memory"{
  description = "Memoria en GB asignada al contenedor del frontend"
  type = number
  default = 1.5
}


# Backend variables for ACI


variable "backend_container_group_name" {
  description = "nombre del grupo de contenedores de ACI."
  type        = string
  default     = "topicos-aci-semestral"
}

variable "backend_container_name" {
  description = "nombre del contenedor de ACI."
  type        = string
  default     = "topicos-container-semestral"
}

variable "backend_container_image" {
  description = "Imagen de container usada por ACI al momento de creación, por ahora es una imagen pública de ejemplo, pero en pipelines posteriores se usará una imagen personalizada almacenada en un ACR."
  type        = string
  default     = "mcr.microsoft.com/azuredocs/aci-helloworld:latest"
}

variable "backend_container_port" {
  description = "Puerto TCP expuesto por el contenedor del backend"
  type        = number
  default     = 5000
}

variable "backend_container_cpu" {
  description = "Núcleos de CPU asignados al contenedor del backend"
  type        = number
  default     = 1
}

variable "backend_container_memory" {
  description = "Memoria en GB asignada al contenedor del backend"
  type        = number
  default     = 1.5
}

variable "tags" {
  description = "Tags applied to all supported resources."
  type        = map(string)
  default = {
    managed_by = "terraform"
    workload   = "task-manager"
  }
}

variable "postgres_host" {
  description = "PostgreSQL server hostname."
  type        = string
  default     = "taskmanager-pg-flex.postgres.database.azure.com"
}

variable "postgres_database" {
  description = "PostgreSQL database name used by the app."
  type        = string
  default     = "taskmanager"
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