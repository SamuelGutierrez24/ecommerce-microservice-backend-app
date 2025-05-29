# Script para desplegar y probar microservicios en Minikube (PowerShell)

Write-Host "==============================================`nIniciando prueba completa de despliegue`n==============================================" -ForegroundColor Cyan

# Iniciar un nuevo Minikube
Write-Host "Iniciando un nuevo Minikube..." -ForegroundColor Yellow
minikube start --cpus=no-limit --memory=no-limit

# Habilitar el addon de ingress
Write-Host "Habilitando addons de Minikube..." -ForegroundColor Yellow
minikube addons enable ingress
minikube addons enable metrics-server

# Verificar estado de Minikube
Write-Host "Verificando estado de Minikube..." -ForegroundColor Yellow
minikube status

# Cambiar al directorio de los manifiestos de Kubernetes
cd k8s

# Crear el namespace jenkins y desplegar Jenkins
Write-Host "==============================================`nDesplegando Jenkins`n==============================================" -ForegroundColor Cyan
kubectl create namespace jenkins
kubectl apply -f jenkins-pv.yml -n jenkins
kubectl apply -f jenkins-rbac.yml -n jenkins
kubectl apply -f jenkins-deployment.yml -n jenkins
kubectl apply -f jenkins-rbac-default.yml