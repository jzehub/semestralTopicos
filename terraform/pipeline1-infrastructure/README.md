# Pipeline 1 - Azure Infrastructure With Terraform

This Terraform project provisions the infrastructure foundation for the CI/CD workflow:

- Resource group
- Virtual network
- Subnet delegated to Azure Container Instances
- NAT Gateway for outbound traffic from the private subnet
- Azure Container Registry
- User-assigned managed identity
- AcrPull role assignment
- Azure Container Instance inside the VNet

## Design Notes

The ACI is deployed with a private IP inside the delegated subnet. It is not directly reachable from the public internet.

The container registry has `admin_enabled = false`. ACI receives a user-assigned managed identity, and that identity receives the `AcrPull` role on the registry. This is preferred over storing registry passwords in Terraform variables.

Pipeline 1 defaults to a public bootstrap image:

```text
mcr.microsoft.com/azuredocs/aci-helloworld:latest
```

This allows infrastructure to be created before Pipeline 2 builds and publishes the real app image. Later, the deployment pipeline can update the ACI to use:

```text
<acr-login-server>/taskmanager-backend:<tag>
```

## Files

```text
providers.tf
variables.tf
main.tf
outputs.tf
terraform.tfvars.example
```

## Usage

From this folder:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
terraform init
terraform validate
terraform plan
terraform apply
```

## Key Outputs

After apply, Terraform prints:

- Resource group name
- VNet name
- ACI subnet ID
- ACR login server
- ACI managed identity client ID
- ACI private IP
- ACI private endpoint

The private endpoint only works from inside the VNet.
