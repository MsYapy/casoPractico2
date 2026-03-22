# Caso Práctico 2 - Despliegue en Azure

## Diagrama de Arquitectura

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                              AZURE CLOUD                                         │
│  ┌───────────────────────────────────────────────────────────────────────────┐  │
│  │                    Resource Group: rg-podman-nginx                         │  │
│  │                                                                            │  │
│  │  ┌─────────────────────────────────────────────────────────────────────┐  │  │
│  │  │                    Virtual Network: vnet-podman                      │  │  │
│  │  │                        10.0.0.0/16                                   │  │  │
│  │  │                                                                      │  │  │
│  │  │  ┌─────────────────────┐                                            │  │  │
│  │  │  │  Subnet: 10.0.1.0/24│                                            │  │  │
│  │  │  │                     │                                            │  │  │
│  │  │  │  ┌───────────────┐  │                                            │  │  │
│  │  │  │  │  VM Linux     │  │                                            │  │  │
│  │  │  │  │  Ubuntu 24.04 │  │                                            │  │  │
│  │  │  │  │               │  │                                            │  │  │
│  │  │  │  │  ┌─────────┐  │  │                                            │  │  │
│  │  │  │  │  │ Podman  │  │  │                                            │  │  │
│  │  │  │  │  │         │  │  │                                            │  │  │
│  │  │  │  │  │ NGINX   │◄─┼──┼─── HTTPS :443 (Internet)                   │  │  │
│  │  │  │  │  │ HTTPS   │  │  │    Certificado X.509 + htpasswd            │  │  │
│  │  │  │  │  └─────────┘  │  │                                            │  │  │
│  │  │  │  └───────────────┘  │                                            │  │  │
│  │  │  └─────────────────────┘                                            │  │  │
│  │  └─────────────────────────────────────────────────────────────────────┘  │  │
│  │                                                                            │  │
│  │  ┌─────────────────────────────────────────────────────────────────────┐  │  │
│  │  │              Azure Kubernetes Service (AKS)                          │  │  │
│  │  │              aks-casopractico2 (1 worker node)                       │  │  │
│  │  │                                                                      │  │  │
│  │  │  ┌─────────────────────────────────────────────────────────────┐    │  │  │
│  │  │  │                 Namespace: casopractico2                     │    │  │  │
│  │  │  │                                                              │    │  │  │
│  │  │  │  ┌─────────────┐         ┌─────────────┐                    │    │  │  │
│  │  │  │  │  Node.js    │         │   Redis     │                    │    │  │  │
│  │  │  │  │  Frontend   │────────►│   Backend   │                    │    │  │  │
│  │  │  │  │  :3000      │         │   :6379     │                    │    │  │  │
│  │  │  │  └──────┬──────┘         └──────┬──────┘                    │    │  │  │
│  │  │  │         │                       │                           │    │  │  │
│  │  │  │         │                       ▼                           │    │  │  │
│  │  │  │         │               ┌───────────────┐                   │    │  │  │
│  │  │  │         │               │     PVC       │                   │    │  │  │
│  │  │  │         │               │  managed-csi  │                   │    │  │  │
│  │  │  │         │               │    1Gi        │                   │    │  │  │
│  │  │  │         │               └───────────────┘                   │    │  │  │
│  │  │  │         ▼                                                   │    │  │  │
│  │  │  │  ┌─────────────┐                                            │    │  │  │
│  │  │  │  │ LoadBalancer│◄─── HTTP :80 (Internet)                    │    │  │  │
│  │  │  │  └─────────────┘                                            │    │  │  │
│  │  │  └─────────────────────────────────────────────────────────────┘    │  │  │
│  │  └─────────────────────────────────────────────────────────────────────┘  │  │
│  │                                                                            │  │
│  │  ┌─────────────────────────────────────────────────────────────────────┐  │  │
│  │  │           Azure Container Registry (ACR)                             │  │  │
│  │  │           acrcp2xxxxxxxx.azurecr.io                                  │  │  │
│  │  │                                                                      │  │  │
│  │  │   ┌──────────────────┐ ┌──────────────────┐ ┌──────────────────┐    │  │  │
│  │  │   │ nginx-https      │ │ nodejs-redis     │ │ redis            │    │  │  │
│  │  │   │ :casopractico2   │ │ :casopractico2   │ │ :casopractico2   │    │  │  │
│  │  │   └──────────────────┘ └──────────────────┘ └──────────────────┘    │  │  │
│  │  └─────────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Diagrama de Flujo de Despliegue

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Terraform  │────►│    ACR      │────►│   Ansible   │────►│    AKS      │
│   init &    │     │   Imágenes  │     │   Podman    │     │  kubectl    │
│   apply     │     │   push      │     │   config    │     │   apply     │
└─────────────┘     └─────────────┘     └─────────────┘     └─────────────┘
      │                   │                   │                   │
      ▼                   ▼                   ▼                   ▼
 ┌─────────┐        ┌─────────┐        ┌─────────┐        ┌─────────┐
 │ RG, VNet│        │ nginx   │        │ NGINX   │        │ Node.js │
 │ VM, ACR │        │ nodejs  │        │ HTTPS   │        │ + Redis │
 │ AKS     │        │ redis   │        │ :443    │        │ + PVC   │
 └─────────┘        └─────────┘        └─────────┘        └─────────┘
```

## Recursos Desplegados en Azure

| Recurso | Nombre | Descripción |
|---------|--------|-------------|
| Resource Group | rg-podman-nginx | Contenedor de todos los recursos |
| Virtual Network | vnet-podman | Red virtual 10.0.0.0/16 |
| Subnet | subnet-podman | Subred 10.0.1.0/24 |
| VM Linux | vm-podman-nginx | Ubuntu 24.04 LTS con Podman |
| Public IP | pip-podman-vm | IP pública para la VM |
| NSG | nsg-podman-vm | Reglas: SSH(22), HTTP(80), HTTPS(443), Node.js(3000) |
| ACR | acrcp2xxxxxxxx | Registro de contenedores privado |
| AKS | aks-casopractico2 | Cluster Kubernetes (1 worker) |

## Descripción del Proceso de Despliegue

### Requisitos Previos
- Azure CLI instalado y autenticado
- Terraform >= 1.0
- Ansible >= 2.9 con colección `containers.podman`
- Docker o Podman local para construir imágenes
- kubectl

### Paso 1: Infraestructura con Terraform
```bash
cd Terraform
terraform init
terraform apply -auto-approve
```
Crea: Resource Group, VNet, Subnet, VM, NSG, ACR, AKS

### Paso 2: Construcción y Push de Imágenes
```bash
./build-push-images.sh
```
Construye y sube al ACR:
- `nginx-https:casopractico2` - NGINX con SSL y autenticación
- `nodejs-redis:casopractico2` - API Node.js
- `redis:casopractico2` - Redis para persistencia

### Paso 3: Configuración VM con Ansible
```bash
cd Ansible
ansible-playbook -i inventory.ini playbook-podman-https.yml
```
Configura Podman y despliega NGINX HTTPS como servicio systemd

### Paso 4: Despliegue en AKS
```bash
./deploy-aks.sh
```
Despliega en Kubernetes: Namespace, PVC, Redis, Node.js, Services

## Descripción de las Aplicaciones

### Aplicación 1: NGINX HTTPS (Podman en VM)
- **Tecnología**: NGINX en contenedor Podman
- **Puerto**: 443 (HTTPS)
- **Seguridad**: 
  - Certificado X.509 autofirmado (365 días)
  - Autenticación básica htpasswd (usuario: admin, password: admin123)
- **Gestión**: Servicio systemd (`podman-nginx-https.service`)
- **Acceso**: `https://<VM_PUBLIC_IP>`

### Aplicación 2: Node.js + Redis (AKS)
- **Frontend**: API Node.js con endpoints REST
  - `GET /items` - Lista todos los items
  - `POST /items` - Guarda item y retorna lista completa
  - `GET /health` - Health check
- **Backend**: Redis con almacenamiento persistente (PVC 1Gi)
- **Persistencia**: Azure Managed Disk via StorageClass `managed-csi`
- **Acceso**: `http://<LOADBALANCER_IP>/items`

## Comandos Útiles

```bash
# Ver estado de la VM
az vm show --resource-group rg-podman-nginx --name vm-podman-nginx --show-details

# Ver pods en AKS
kubectl get pods -n casopractico2

# Ver IP del LoadBalancer
kubectl get svc nodejs-service -n casopractico2

# Probar API Node.js
curl -X POST http://<LB_IP>/items -H "Content-Type: application/json" -d '{"item":"test"}'
curl http://<LB_IP>/items

# Probar NGINX HTTPS
curl -k -u admin:admin123 https://<VM_IP>

# Gestionar servicio NGINX en VM
sudo systemctl status podman-nginx-https
sudo systemctl restart podman-nginx-https
```

## Estructura del Proyecto

```
.
├── Terraform/
│   ├── main.tf          # Provider y Resource Group
│   ├── network.tf       # VNet, Subnet, Public IP, NIC
│   ├── security.tf      # NSG con reglas
│   ├── vm.tf            # VM Linux
│   ├── acr.tf           # Azure Container Registry
│   ├── aks.tf           # Azure Kubernetes Service
│   └── vars.tf          # Variables
├── Ansible/
│   ├── inventory.ini    # Inventario de hosts
│   └── playbook-podman-https.yml  # Playbook principal
├── kubernetes/
│   ├── namespace.yaml   # Namespace casopractico2
│   ├── redis-pvc.yaml   # PersistentVolumeClaim
│   ├── redis-deployment.yaml
│   ├── redis-service.yaml
│   ├── nodejs-deployment.yaml
│   └── nodejs-service.yaml
├── app-nodejs/          # Código fuente API Node.js
├── app-nginx-https/     # Dockerfile NGINX con SSL
├── build-push-images.sh # Script para construir imágenes
└── deploy-aks.sh        # Script para desplegar en AKS
```
