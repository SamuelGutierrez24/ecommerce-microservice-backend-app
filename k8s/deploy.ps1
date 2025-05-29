# Deploy Ecommerce Microservices to Minikube
# Run this script from the root directory of your project

Write-Host "Starting deployment of Ecommerce Microservices to Minikube..." -ForegroundColor Green

# Deploy core infrastructure services first
Write-Host "Deploying Zipkin..." -ForegroundColor Yellow
kubectl apply -f k8s/zipkin.yml

Write-Host "Deploying Service Discovery (Eureka)..." -ForegroundColor Yellow
kubectl apply -f k8s/service-discovery.yml

Write-Host "Waiting for Service Discovery to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=service-discovery -n ecommerce-microservices --timeout=300s

Write-Host "Deploying Cloud Config Server..." -ForegroundColor Yellow
kubectl apply -f k8s/cloud-config.yml

Write-Host "Waiting for Cloud Config to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=cloud-config -n ecommerce-microservices --timeout=300s

# Deploy business services
Write-Host "Deploying API Gateway..." -ForegroundColor Yellow
kubectl apply -f k8s/api-gateway.yml

Write-Host "Deploying Business Services..." -ForegroundColor Yellow
kubectl apply -f k8s/order-service.yml
kubectl apply -f k8s/payment-service.yml
kubectl apply -f k8s/product-service.yml
kubectl apply -f k8s/shipping-service.yml
kubectl apply -f k8s/user-service.yml
kubectl apply -f k8s/favourite-service.yml
kubectl apply -f k8s/proxy-client.yml

Write-Host "Deployment completed!" -ForegroundColor Green
Write-Host ""
Write-Host "Services Status:" -ForegroundColor Cyan
kubectl get pods -n ecommerce-microservices
Write-Host ""
Write-Host "Services URLs (using Minikube IP):" -ForegroundColor Cyan
$MINIKUBE_IP = minikube ip
Write-Host "Eureka Dashboard: http://${MINIKUBE_IP}:30761" -ForegroundColor Blue
Write-Host "API Gateway: http://${MINIKUBE_IP}:30080" -ForegroundColor Blue
Write-Host "Zipkin Dashboard: http://${MINIKUBE_IP}:30411" -ForegroundColor Blue
Write-Host "Cloud Config Server: http://${MINIKUBE_IP}:30296" -ForegroundColor Blue
Write-Host "Proxy Client: http://${MINIKUBE_IP}:30900" -ForegroundColor Blue
Write-Host ""
Write-Host "Individual Services:" -ForegroundColor Cyan
Write-Host "Order Service: http://${MINIKUBE_IP}:30300" -ForegroundColor Blue
Write-Host "Payment Service: http://${MINIKUBE_IP}:30400" -ForegroundColor Blue
Write-Host "Product Service: http://${MINIKUBE_IP}:30500" -ForegroundColor Blue
Write-Host "Shipping Service: http://${MINIKUBE_IP}:30600" -ForegroundColor Blue
Write-Host "User Service: http://${MINIKUBE_IP}:30700" -ForegroundColor Blue
Write-Host "Favourite Service: http://${MINIKUBE_IP}:30800" -ForegroundColor Blue
