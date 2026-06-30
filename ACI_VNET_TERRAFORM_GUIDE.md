# Azure Container Instance Inside VNet With Terraform

This guide explains the deployment we created for the Task Manager backend using:

- Azure Virtual Network
- Azure Container Registry
- Azure Database for PostgreSQL Flexible Server
- Azure Container Instance
- Terraform

The main objective was to deploy the backend container as a private Azure Container Instance inside a VNet, while using Terraform only for the ACI part.

## Final Architecture

```text
Azure Resource Group: topicos-2

VNet: aci-project
  default subnet
    10.0.0.0/24

  aci-subnet
    10.0.1.0/24
    Delegation: Microsoft.ContainerInstance/containerGroups

  postgres-subnet
    10.0.2.0/24
    Delegation: Microsoft.DBforPostgreSQL/flexibleServers

Azure Container Registry: acicontainer
  Image: acicontainer.azurecr.io/taskmanager-backend:latest

Azure Database for PostgreSQL Flexible Server
  Server: aci-project-database
  Database: aci-task-manager-bd
  Private access through postgres-subnet

Azure Container Instance
  Name: taskmanager-backend-aci
  Private IP: 10.0.1.4
  Subnet: aci-subnet
  Port: 5000
```

## What We Created Manually In Azure

Most supporting resources were created directly in Azure Portal.

### Resource Group

We used:

```text
topicos-2
```

This resource group contains the VNet, ACR, PostgreSQL server, and ACI.

### Virtual Network

We created a VNet:

```text
Name: aci-project
Region: Central US
```

The VNet contains three subnets:

```text
default
10.0.0.0/24
No delegation
```

```text
aci-subnet
10.0.1.0/24
Delegation: Microsoft.ContainerInstance/containerGroups
```

```text
postgres-subnet
10.0.2.0/24
Delegation: Microsoft.DBforPostgreSQL/flexibleServers
```

The important point is that ACI and PostgreSQL each use their own subnet.

### Azure Container Registry

We created:

```text
Name: acicontainer
Login server: acicontainer.azurecr.io
SKU: Basic
Public network access: Enabled
Admin user: Enabled
```

The registry stores the backend Docker image.

### Backend Image

We logged in to ACR:

```powershell
az acr login --name acicontainer
```

Then built the backend image:

```powershell
docker build -t acicontainer.azurecr.io/taskmanager-backend:latest ./backend
```

Then pushed it:

```powershell
docker push acicontainer.azurecr.io/taskmanager-backend:latest
```

The final image used by ACI is:

```text
acicontainer.azurecr.io/taskmanager-backend:latest
```

### PostgreSQL Flexible Server

We created Azure Database for PostgreSQL Flexible Server with private access:

```text
Server name: aci-project-database
Database name: aci-task-manager-bd
Admin username: taskadmin
Region: Central US
Connectivity: Private access / VNet integration
VNet: aci-project
Subnet: postgres-subnet
```

The private access configuration means the database is not exposed publicly on the internet. Resources inside the VNet can reach it through private networking and private DNS.

## Why We Used Private Access

Because the project goal was to deploy ACI inside a VNet, private database access is the better architecture.

Instead of this:

```text
ACI private subnet
  -> internet/public endpoint
  -> PostgreSQL
```

we created this:

```text
ACI inside VNet
  -> private network
  -> PostgreSQL inside private VNet integration
```

Benefits:

- PostgreSQL is not publicly exposed.
- Backend connects to the database privately.
- The architecture better demonstrates VNet-based deployment.

## What Terraform Creates

Terraform creates only this resource:

```text
Azure Container Instance: taskmanager-backend-aci
```

Terraform does not create:

- Resource group
- VNet
- Subnets
- ACR
- PostgreSQL server

Those resources already exist in Azure. Terraform references them and then deploys the ACI into the existing `aci-subnet`.

## Terraform Files

The Terraform files are in:

```text
terraform/
```

The files are:

```text
providers.tf
variables.tf
main.tf
outputs.tf
terraform.tfvars.example
terraform.tfvars
```

`terraform.tfvars` contains real secret values and should not be committed.

## providers.tf

This file configures Terraform and the Azure provider.

```hcl
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
    }
  }
}

provider "azurerm" {
  features {}
}
```

Explanation:

- `required_version` defines the minimum Terraform version.
- `azurerm` is the official Azure provider.
- `features {}` is required by the AzureRM provider.

## variables.tf

This file defines configurable values used by Terraform.

Important variables:

```hcl
variable "resource_group_name" {
  default = "topicos-2"
}
```

This points Terraform to the existing resource group.

```hcl
variable "vnet_name" {
  default = "aci-project"
}
```

This points Terraform to the existing VNet.

```hcl
variable "aci_subnet_name" {
  default = "aci-subnet"
}
```

This points Terraform to the existing subnet where ACI will be deployed.

```hcl
variable "container_image" {
  default = "acicontainer.azurecr.io/taskmanager-backend:latest"
}
```

This is the Docker image used by the backend container.

```hcl
variable "postgres_database" {
  default = "aci-task-manager-bd"
}
```

This is the PostgreSQL database used by the backend app.

Sensitive variables:

```hcl
variable "acr_username" {
  sensitive = true
}

variable "acr_password" {
  sensitive = true
}

variable "postgres_password" {
  sensitive = true
}
```

These are marked sensitive because they contain credentials.

## terraform.tfvars

The real values are placed in:

```text
terraform.tfvars
```

Example:

```hcl
acr_username      = "acicontainer"
acr_password      = "your-acr-password"
postgres_password = "your-postgres-password"
```

Terraform automatically reads this file.

This file should not be committed because it contains secrets.

## main.tf

This is the most important Terraform file.

### Reading Existing Resource Group

```hcl
data "azurerm_resource_group" "main" {
  name = var.resource_group_name
}
```

This does not create a resource group. It reads the existing one.

### Reading Existing VNet

```hcl
data "azurerm_virtual_network" "main" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.main.name
}
```

This reads the existing VNet named `aci-project`.

### Reading Existing ACI Subnet

```hcl
data "azurerm_subnet" "aci" {
  name                 = var.aci_subnet_name
  virtual_network_name = data.azurerm_virtual_network.main.name
  resource_group_name  = data.azurerm_resource_group.main.name
}
```

This reads the existing `aci-subnet`.

This subnet is delegated to:

```text
Microsoft.ContainerInstance/containerGroups
```

### Building The Database URL

```hcl
locals {
  database_url = "postgresql://${var.postgres_username}:${var.postgres_password}@${var.postgres_host}:5432/${var.postgres_database}?sslmode=require"
}
```

This creates the connection string used by Flask.

It becomes:

```text
postgresql://taskadmin:<password>@aci-project-database.postgres.database.azure.com:5432/aci-task-manager-bd?sslmode=require
```

The Flask app reads this value from the `DATABASE_URL` environment variable.

### Creating The Azure Container Instance

```hcl
resource "azurerm_container_group" "backend" {
  name                = var.container_group_name
  location            = var.location
  resource_group_name = data.azurerm_resource_group.main.name
  os_type             = "Linux"
  ip_address_type     = "Private"
  subnet_ids          = [data.azurerm_subnet.aci.id]
```

This creates the ACI container group.

Important settings:

```hcl
ip_address_type = "Private"
```

This means the container does not get a public internet IP.

```hcl
subnet_ids = [data.azurerm_subnet.aci.id]
```

This places the ACI inside `aci-subnet`.

### ACR Credentials

```hcl
image_registry_credential {
  server   = var.acr_server
  username = var.acr_username
  password = var.acr_password
}
```

This allows ACI to pull the private image from ACR.

### Container Definition

```hcl
container {
  name   = var.container_name
  image  = var.container_image
  cpu    = 1
  memory = 1.5
```

This defines the backend container and its resource limits.

```hcl
ports {
  port     = 5000
  protocol = "TCP"
}
```

The backend Flask app listens on port `5000`.

```hcl
secure_environment_variables = {
  DATABASE_URL = local.database_url
}
```

This passes the database connection string securely to the container.

## outputs.tf

This file prints useful information after `terraform apply`.

```hcl
output "container_group_name" {
  value = azurerm_container_group.backend.name
}
```

Prints the ACI name.

```hcl
output "container_group_private_ip" {
  value = azurerm_container_group.backend.ip_address
}
```

Prints the private IP.

```hcl
output "backend_health_url_private" {
  value = "http://${azurerm_container_group.backend.ip_address}:5000/health"
}
```

Prints the private health check URL.

In our deployment, Terraform returned:

```text
container_group_name = "taskmanager-backend-aci"
container_group_private_ip = "10.0.1.4"
backend_health_url_private = "http://10.0.1.4:5000/health"
```

## Terraform Commands Used

From the `terraform/` directory:

```powershell
terraform init
```

Downloads the Azure provider.

```powershell
terraform plan
```

Shows what Terraform will create.

The plan showed:

```text
Plan: 1 to add, 0 to change, 0 to destroy
```

That means Terraform would create only the ACI.

```powershell
terraform apply
```

Creates the ACI.

After confirmation, Terraform created:

```text
taskmanager-backend-aci
```

## How We Verified The ACI

Terraform output showed:

```text
Private IP: 10.0.1.4
```

The subnet is:

```text
aci-subnet: 10.0.1.0/24
```

Because `10.0.1.4` is inside `10.0.1.0/24`, this confirms the ACI is inside the `aci-subnet`.

In Azure Portal, we can also verify:

```text
Container instances
  -> taskmanager-backend-aci
```

Expected values:

```text
Status: Running
IP address type: Private
Private IP: 10.0.1.4
Virtual network: aci-project
Subnet: aci-subnet
Image: acicontainer.azurecr.io/taskmanager-backend:latest
```

## Why The Health URL Is Private

Terraform outputs:

```text
http://10.0.1.4:5000/health
```

But this URL is not reachable from a normal laptop browser because `10.0.1.4` is a private VNet IP.

Only resources inside the VNet can access it, such as:

- A VM inside the same VNet
- Another container inside the same VNet
- A VPN-connected machine
- Application Gateway or another internal/public gateway

This is expected. The backend is private by design.

## Current State

The backend ACI is running privately inside the VNet.

Current result:

```text
ACI name: taskmanager-backend-aci
Private IP: 10.0.1.4
Subnet: aci-subnet
Database: aci-task-manager-bd
Image: acicontainer.azurecr.io/taskmanager-backend:latest
```

## Next Possible Steps

To test the backend endpoint, create a small VM inside the same VNet and run:

```bash
curl http://10.0.1.4:5000/health
```

Expected result:

```json
{"status":"healthy"}
```

To make the full app public later, add a public entry point such as:

- Application Gateway
- VPN plus private access
- A public reverse proxy
- Azure Container Apps instead of ACI for a full public frontend/backend app

For this project stage, the important result is that the backend container was deployed privately inside the VNet using Terraform.
