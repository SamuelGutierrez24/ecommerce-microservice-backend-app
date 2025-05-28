# Undeploy Ecommerce Microservices from Minikube
# Run this script to clean up all deployed resources

Write-Host "Undeploying Ecommerce Microservices from Minikube..." -ForegroundColor Red

# Delete all services in reverse order
Write-Host "Deleting business services..." -ForegroundColor Yellow
kubectl delete -f k8s/proxy-client.yml --ignore-not-found=true
kubectl delete -f k8s/favourite-service.yml --ignore-not-found=true
kubectl delete -f k8s/user-service.yml --ignore-not-found=true
kubectl delete -f k8s/shipping-service.yml --ignore-not-found=true
kubectl delete -f k8s/product-service.yml --ignore-not-found=true
kubectl delete -f k8s/payment-service.yml --ignore-not-found=true
kubectl delete -f k8s/order-service.yml --ignore-not-found=true
kubectl delete -f k8s/api-gateway.yml --ignore-not-found=true

Write-Host "Deleting infrastructure services..." -ForegroundColor Yellow
kubectl delete -f k8s/cloud-config.yml --ignore-not-found=true
kubectl delete -f k8s/service-discovery.yml --ignore-not-found=true
kubectl delete -f k8s/zipkin.yml --ignore-not-found=true

Write-Host "Deleting namespace..." -ForegroundColor Yellow
kubectl delete -f k8s/namespace.yml --ignore-not-found=true

Write-Host "Cleanup completed!" -ForegroundColor Green
