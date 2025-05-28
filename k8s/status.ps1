# Check status of Ecommerce Microservices deployment
Write-Host "Checking Ecommerce Microservices Status..." -ForegroundColor Green
Write-Host ""

# Check if namespace exists
Write-Host "Namespace Status:" -ForegroundColor Cyan
kubectl get namespace ecommerce-microservices 2>$null
if ($LASTEXITCODE -ne 0) {
    Write-Host "Namespace 'ecommerce-microservices' not found. Run deploy.ps1 first." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Pods Status:" -ForegroundColor Cyan
kubectl get pods -n ecommerce-microservices -o wide

Write-Host ""
Write-Host "Services Status:" -ForegroundColor Cyan
kubectl get services -n ecommerce-microservices

Write-Host ""
Write-Host "Deployments Status:" -ForegroundColor Cyan
kubectl get deployments -n ecommerce-microservices

Write-Host ""
Write-Host "Persistent Volumes (if any):" -ForegroundColor Cyan
kubectl get pv

Write-Host ""
Write-Host "Events (last 10):" -ForegroundColor Cyan
kubectl get events -n ecommerce-microservices --sort-by='.lastTimestamp' | Select-Object -Last 10

Write-Host ""
Write-Host "Service URLs (using Minikube IP):" -ForegroundColor Cyan
try {
    $MINIKUBE_IP = minikube ip
    Write-Host "Minikube IP: $MINIKUBE_IP" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Main Services:" -ForegroundColor Green
    Write-Host "  Eureka Dashboard:     http://${MINIKUBE_IP}:30761" -ForegroundColor Blue
    Write-Host "  API Gateway:          http://${MINIKUBE_IP}:30080" -ForegroundColor Blue
    Write-Host "  Zipkin Dashboard:     http://${MINIKUBE_IP}:30411" -ForegroundColor Blue
    Write-Host "  Cloud Config Server:  http://${MINIKUBE_IP}:30296" -ForegroundColor Blue
    Write-Host "  Proxy Client:         http://${MINIKUBE_IP}:30900/app" -ForegroundColor Blue
    Write-Host ""
    Write-Host "Business Services:" -ForegroundColor Green
    Write-Host "  Order Service:        http://${MINIKUBE_IP}:30300/order-service" -ForegroundColor Blue
    Write-Host "  Payment Service:      http://${MINIKUBE_IP}:30400/payment-service" -ForegroundColor Blue
    Write-Host "  Product Service:      http://${MINIKUBE_IP}:30500/product-service" -ForegroundColor Blue
    Write-Host "  Shipping Service:     http://${MINIKUBE_IP}:30600/shipping-service" -ForegroundColor Blue
    Write-Host "  User Service:         http://${MINIKUBE_IP}:30700/user-service" -ForegroundColor Blue
    Write-Host "  Favourite Service:    http://${MINIKUBE_IP}:30800/favourite-service" -ForegroundColor Blue
} catch {
    Write-Host "Could not get Minikube IP. Make sure Minikube is running." -ForegroundColor Red
}

Write-Host ""
Write-Host "Health Check Commands:" -ForegroundColor Cyan
Write-Host "kubectl logs -f deployment/api-gateway -n ecommerce-microservices" -ForegroundColor Yellow
Write-Host "kubectl logs -f deployment/service-discovery -n ecommerce-microservices" -ForegroundColor Yellow
Write-Host "kubectl describe pod <pod-name> -n ecommerce-microservices" -ForegroundColor Yellow
