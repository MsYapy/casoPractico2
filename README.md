# Azure VM con Podman y NGINX

Infraestructura como código para desplegar una VM en Azure con Podman ejecutando NGINX desde Azure Container Registry.

## Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                                   AZURE CLOUD                                    │
│                                                                                  │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │                    Resource Group: rg-podman-nginx                       │    │
│  │                                                                          │    │
│  │   ┌──────────────────────────────────────────────────────────────────┐  │    │
│  │   │                  Virtual Network: vnet-podman                     │  │    │
│  │   │                      10.0.0.0/16                                  │  │    │
│  │   │                                                                   │  │    │
│  │   │   ┌──────────────────────────────────────────────────────────┐   │  │    │
│  │   │   │              Subnet: subnet-podman                        │   │  │    │
│  │   │   │                  10.0.1.0/24                              │   │  │    │
│  │   │   │                                                           │   │  │    │
│  │   │   │   ┌───────────────────────────────────────────────────┐  │   │  │    │
│  │   │   │   │         VM: vm-podman-nginx (Ubuntu 24.04)        │  │   │  │    │
│  │   │   │   │                Standard_D2s_v3                     │  │   │  │    │
│  │   │   │   │                                                    │  │   │  │    │
│  │   │   │   │   ┌────────────────────────────────────────────┐  │  │   │  │    │
│  │   │   │   │   │              PODMAN                         │  │   │  │    │
│  │   │   │   │   │   ┌────────────────────────────────────┐   │  │   │  │    │
│  │   │   │   │   │   │     Container: nginx-webserver     │   │  │   │  │    │
│  │   │   │   │   │   │  devopsyapy.azurecr.io/nginx:      │   │  │   │  │    │
│  │   │   │   │   │   │         casopractico2              │   │  │   │  │    │
│  │   │   │   │   │   │           :80 ←──────────────────────────────────┐    │
│  │   │   │   │   │   └────────────────────────────────────┘   │  │   │  │    │
│  │   │   │   │   └────────────────────────────────────────────┘  │   │  │    │
│  │   │   │   └───────────────────────────────────────────────────┘  │   │  │    │
│  │   │   │                          │                                │   │  │    │
│  │   │   └──────────────────────────┼────────────────────────────────┘   │  │    │
│  │   │                              │                                     │  │    │
│  │   └──────────────────────────────┼─────────────────────────────────────┘  │    │
│  │                                  │                                        │    │
│  │   ┌──────────────────┐    ┌──────┴───────┐    ┌─────────────────────┐    │    │
│  │   │  NSG: nsg-podman │    │  NIC: nic-   │    │  Public IP: pip-    │    │    │
│  │   │       -vm        │◄───│  podman-vm   │◄───│    podman-vm        │    │    │
│  │   │  ┌────────────┐  │    └──────────────┘    │   20.69.158.189     │    │    │
│  │   │  │ SSH:22  ✓  │  │                        └──────────┬──────────┘    │    │
│  │   │  │ HTTP:80 ✓  │  │                                   │               │    │
│  │   │  └────────────┘  │                                   │               │    │
│  │   └──────────────────┘                                   │               │    │
│  │                                                          │               │    │
│  └──────────────────────────────────────────────────────────┼───────────────┘    │
│                                                             │                    │
│  ┌──────────────────────────────────────┐                   │                    │
│  │  Azure Container Registry (ACR)      │                   │                    │
│  │  devopsyapy.azurecr.io               │                   │                    │
│  │  └─ nginx:casopractico2              │                   │                    │
│  └──────────────────────────────────────┘                   │                    │
│                                                             │                    │
└─────────────────────────────────────────────────────────────┼────────────────────┘
                                                              │
                    ┌─────────────────────────────────────────┘
                    │
                    ▼
┌───────────────────────────────────────────────────────────────────────────────────┐
│                              LOCAL (WSL)                                          │
│                                                                                   │
│   ┌─────────────┐         ┌─────────────┐         ┌─────────────────────────┐    │
│   │  Terraform  │────────►│   Azure     │────────►│  Crea infraestructura   │    │
│   │             │         │   API       │         │  (VM, VNet, NSG, etc.)  │    │
│   └─────────────┘         └─────────────┘         └─────────────────────────┘    │
│                                                                                   │
│   ┌─────────────┐         ┌─────────────┐         ┌─────────────────────────┐    │
│   │   Ansible   │────────►│    SSH      │────────►│  Configura VM:          │    │
│   │             │         │  :22        │         │  - Instala Podman       │    │
│   └─────────────┘         └─────────────┘         │  - Pull imagen ACR      │    │
│                                                   │  - Ejecuta contenedor   │    │
│                                                   └─────────────────────────┘    │
└───────────────────────────────────────────────────────────────────────────────────┘

                    │
                    │  HTTP :80
                    ▼
            ┌───────────────┐
            │   Usuario     │
            │   Navegador   │
            │ http://IP:80  │
            └───────────────┘
```

## Flujo de Despliegue

```
1. Terraform ──► Crea Resource Group, VNet, Subnet, NSG, Public IP, NIC, VM
                          │
2. Terraform ──► Genera clave SSH y guarda en ssh_key.pem
                          │
3. Terraform ──► Output: IP pública de la VM
                          │
4. Ansible   ──► Conecta por SSH a la VM
                          │
5. Ansible   ──► Instala Podman
                          │
6. Ansible   ──► Login a ACR (devopsyapy.azurecr.io)
                          │
7. Ansible   ──► Pull nginx de Docker Hub, tag y push a ACR
                          │
8. Ansible   ──► Ejecuta contenedor desde ACR en puerto 80
                          │
9. Usuario   ──► Accede a http://20.69.158.189
```

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
