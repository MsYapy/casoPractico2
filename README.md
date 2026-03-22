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
│  │  │  │  │  API        │────────►│   Backend   │                    │    │  │  │
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
│  │  │           acrcp2xxxxxxxx.azurecr.io (opcional)                       │  │  │
│  │  └─────────────────────────────────────────────────────────────────────┘  │  │
│  └───────────────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────────────┘
```

## Diagrama de Flujo de Despliegue

```
┌─────────────┐     ┌─────────────┐     ┌─────────────┐
│  Terraform  │────►│   Ansible   │────►│   Ansible   │
│   init &    │     │   VM +      │     │    AKS      │
│   apply     │     │   Podman    │     │   Deploy    │
└─────────────┘     └─────────────┘     └─────────────┘
      │                   │                   │
      ▼                   ▼                   ▼
 ┌─────────┐        ┌─────────┐        ┌─────────┐
 │ RG, VNet│        │ NGINX   │        │ Node.js │
 │ VM, ACR │        │ HTTPS   │        │ + Redis │
 │ AKS     │        │ :443    │        │ + PVC   │
 └─────────┘        └─────────┘        └─────────┘
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
| ACR | acrcp2xxxxxxxx | Registro de contenedores privado (opcional) |
| AKS | aks-casopractico2 | Cluster Kubernetes (1 worker) |

## Descripción del Proceso de Despliegue

### Requisitos Previos
- Azure CLI instalado y autenticado
- Terraform >= 1.0
- Ansible >= 2.9 con colección `containers.podman`
- kubectl (se instala con `az aks install-cli`)

### Paso 1: Infraestructura con Terraform
```bash
cd Terraform
terraform init
terraform apply -auto-approve

# Guardar clave SSH
terraform output -raw private_key > ../ssh_key.pem
cp ../ssh_key.pem ~/ssh_key.pem
chmod 600 ~/ssh_key.pem

# Actualizar inventario Ansible
PUBLIC_IP=$(terraform output -raw public_ip)
cat > ../Ansible/inventory.ini << EOF
[webservers]
${PUBLIC_IP} ansible_user=azureuser ansible_ssh_private_key_file=~/ssh_key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF
```

### Paso 2: Configuración VM con Ansible (NGINX HTTPS)
```bash
cd ../Ansible
ansible-playbook -i inventory.ini playbook-build-local.yml
```
Construye la imagen NGINX localmente en la VM con Podman y la ejecuta como servicio systemd.

### Paso 3: Configurar kubectl
```bash
# Instalar kubectl
sudo az aks install-cli

# Obtener credenciales del AKS
az aks get-credentials --resource-group rg-podman-nginx --name aks-casopractico2
```

### Paso 4: Despliegue en AKS con Ansible
```bash
cd Ansible
export ACR_SERVER="dummy"
export ACR_USER="dummy"
export ACR_PASS="dummy"
ansible-playbook playbook-deploy-aks.yml
```
Despliega Node.js + Redis en AKS usando imágenes públicas.

## Descripción de las Aplicaciones

### Aplicación 1: NGINX HTTPS (Podman en VM)
- **Tecnología**: NGINX en contenedor Podman (construido localmente)
- **Puerto**: 443 (HTTPS)
- **Seguridad**: 
  - Certificado X.509 autofirmado (365 días)
  - Autenticación básica htpasswd (usuario: admin, password: admin123)
- **Gestión**: Servicio systemd (`podman-nginx-https.service`)
- **Acceso**: `https://<VM_PUBLIC_IP>`

### Aplicación 2: Node.js + Redis (AKS)
- **Frontend**: API Node.js con endpoints REST
  - `GET /` - Info de la API
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
/usr/local/bin/kubectl get pods -n casopractico2

# Ver IP del LoadBalancer
/usr/local/bin/kubectl get svc nodejs-service -n casopractico2

# Probar API Node.js
curl http://<LB_IP>/items
curl -X POST http://<LB_IP>/items -H "Content-Type: application/json" -d '{"item":"test"}'

# Probar NGINX HTTPS
curl -k -u admin:admin123 https://<VM_IP>

# Gestionar servicio NGINX en VM
ssh -i ~/ssh_key.pem azureuser@<VM_IP>
sudo systemctl status podman-nginx-https
sudo systemctl restart podman-nginx-https

# Eliminar recursos
cd Terraform
terraform destroy -auto-approve
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
│   ├── inventory.ini              # Inventario de hosts
│   ├── playbook-build-local.yml   # Construye NGINX en VM
│   └── playbook-deploy-aks.yml    # Despliega en AKS
├── kubernetes/
│   ├── namespace.yaml
│   ├── redis-pvc.yaml
│   ├── redis-deployment.yaml
│   ├── redis-service.yaml
│   ├── nodejs-deployment.yaml
│   └── nodejs-service.yaml
├── app-nodejs/          # Código fuente API Node.js
├── app-nginx-https/     # Dockerfile NGINX con SSL
└── PROBLEMAS-SOLUCIONADOS.txt  # Documentación de problemas
```

## Problemas Comunes

Ver el archivo `PROBLEMAS-SOLUCIONADOS.txt` para una lista detallada de problemas encontrados y sus soluciones, incluyendo:
- Error de VM Size en AKS
- Permisos de clave SSH en WSL
- Configuración de registros en Podman
- Instalación de kubectl en WSL
