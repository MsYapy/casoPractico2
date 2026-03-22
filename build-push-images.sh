#!/bin/bash
set -e

# Obtener nombre del ACR desde Terraform
ACR_NAME=$(terraform -chdir=Terraform output -raw acr_name)
ACR_LOGIN_SERVER=$(terraform -chdir=Terraform output -raw acr_login_server)

echo "=== Login a Azure Container Registry: $ACR_NAME ==="
az acr login --name $ACR_NAME

echo "=== Construyendo imagen Node.js ==="
cd app-nodejs
docker build -t ${ACR_LOGIN_SERVER}/nodejs-redis:casopractico2 .
docker push ${ACR_LOGIN_SERVER}/nodejs-redis:casopractico2
cd ..

echo "=== Construyendo imagen NGINX HTTPS ==="
cd app-nginx-https
docker build -t ${ACR_LOGIN_SERVER}/nginx-https:casopractico2 .
docker push ${ACR_LOGIN_SERVER}/nginx-https:casopractico2
cd ..

echo "=== Descargando y subiendo imagen Redis ==="
docker pull redis:alpine
docker tag redis:alpine ${ACR_LOGIN_SERVER}/redis:casopractico2
docker push ${ACR_LOGIN_SERVER}/redis:casopractico2

echo "=== Imágenes subidas exitosamente ==="
az acr repository list --name $ACR_NAME --output table
