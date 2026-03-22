#!/bin/bash
set -e

echo "=== Destruyendo Infraestructura ==="

cd Terraform
terraform destroy -auto-approve

# Limpiar archivos generados
cd ..
rm -f ssh_key.pem
echo "[webservers]" > Ansible/inventory.ini

echo "Infraestructura destruida correctamente."
