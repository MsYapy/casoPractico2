#!/bin/bash
set -e

# Obtener nombre del ACR desde Terraform
ACR_LOGIN_SERVER=$(terraform -chdir=Terraform output -raw acr_login_server)

echo "=== Obteniendo credenciales de AKS ==="
az aks get-credentials --resource-group rg-podman-nginx --name aks-casopractico2 --overwrite-existing

echo "=== Actualizando manifiestos con ACR: $ACR_LOGIN_SERVER ==="
# Reemplazar el nombre del ACR en los manifiestos
sed -i "s|devopsyapy.azurecr.io|${ACR_LOGIN_SERVER}|g" kubernetes/*.yaml

echo "=== Aplicando manifiestos de Kubernetes ==="
kubectl apply -f kubernetes/namespace.yaml
kubectl apply -f kubernetes/redis-pvc.yaml
kubectl apply -f kubernetes/redis-deployment.yaml
kubectl apply -f kubernetes/redis-service.yaml
kubectl apply -f kubernetes/nodejs-deployment.yaml
kubectl apply -f kubernetes/nodejs-service.yaml

echo "=== Esperando a que los pods estén listos ==="
kubectl wait --for=condition=ready pod -l app=redis -n casopractico2 --timeout=180s
kubectl wait --for=condition=ready pod -l app=nodejs-app -n casopractico2 --timeout=180s

echo "=== Estado del despliegue ==="
kubectl get all -n casopractico2

echo "=== IP externa del servicio Node.js ==="
echo "Esperando IP externa..."
sleep 30
kubectl get svc nodejs-service -n casopractico2
