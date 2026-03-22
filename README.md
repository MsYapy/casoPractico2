# Azure VM con Podman y NGINX

Infraestructura como código para desplegar una VM en Azure con Podman ejecutando NGINX desde Azure Container Registry.

## Requisitos

- Azure CLI autenticado (`az login`)
- Terraform
- Ansible
- Azure Container Registry (ACR) existente

## Configuración

1. Edita `Terraform/terraform.tfvars` con tu subscription_id

2. Exporta las credenciales del ACR:
```bash
export ACR_LOGIN_SERVER="tu-acr.azurecr.io"
export ACR_USERNAME="tu-acr-username"
export ACR_PASSWORD="tu-acr-password"
```

## Despliegue

```bash
chmod +x deploy.sh
./deploy.sh
```

## Destruir infraestructura

```bash
./destroy.sh
```

## Estructura

- `Terraform/` - Infraestructura de Azure (VM, VNet, NSG, etc.)
- `Ansible/` - Configuración de la VM (Podman, NGINX)
- `deploy.sh` - Script de despliegue automatizado
- `destroy.sh` - Script para eliminar recursos
