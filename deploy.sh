#!/bin/bash
set -e

echo "=== Despliegue de Infraestructura Azure + Podman + NGINX ==="

# Colores para output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Terraform
echo -e "\n${YELLOW}[1/5] Inicializando Terraform...${NC}"
cd Terraform
terraform init

echo -e "\n${YELLOW}[2/5] Validando configuración...${NC}"
terraform validate

echo -e "\n${YELLOW}[3/5] Aplicando infraestructura (esto puede tomar unos minutos)...${NC}"
terraform apply -auto-approve

# 4. Guardar la clave SSH
echo -e "\n${YELLOW}[4/5] Guardando clave SSH...${NC}"
terraform output -raw private_key > ../ssh_key.pem
chmod 600 ../ssh_key.pem

# Generar inventario de Ansible
PUBLIC_IP=$(terraform output -raw public_ip)
echo -e "\n${GREEN}IP Pública de la VM: ${PUBLIC_IP}${NC}"

cat > ../Ansible/inventory.ini << EOF
[webservers]
${PUBLIC_IP} ansible_user=azureuser ansible_ssh_private_key_file=../ssh_key.pem ansible_ssh_common_args='-o StrictHostKeyChecking=no'
EOF

cd ..

# 5. Ansible
echo -e "\n${YELLOW}[5/5] Configurando VM con Ansible...${NC}"
echo "Esperando 30 segundos para que la VM esté lista..."
sleep 30

cd Ansible
ansible-galaxy collection install -r requirements.yml
ansible-playbook -i inventory.ini playbook.yml

echo -e "\n${GREEN}=== Despliegue completado ===${NC}"
echo -e "Accede a NGINX en: ${GREEN}http://${PUBLIC_IP}${NC}"
echo -e "SSH a la VM: ${GREEN}ssh -i ../ssh_key.pem azureuser@${PUBLIC_IP}${NC}"
