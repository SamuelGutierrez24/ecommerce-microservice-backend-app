# Open Ecommerce Microservices Dashboards
Write-Host "Opening Ecommerce Microservices Dashboards..." -ForegroundColor Green

try {
    $MINIKUBE_IP = minikube ip
    Write-Host "Minikube IP: $MINIKUBE_IP" -ForegroundColor Yellow
    
    # Define URLs
    $EUREKA_URL = "http://${MINIKUBE_IP}:30761"
    $ZIPKIN_URL = "http://${MINIKUBE_IP}:30411"
    $API_GATEWAY_URL = "http://${MINIKUBE_IP}:30080"
    $CONFIG_URL = "http://${MINIKUBE_IP}:30296"
    
    Write-Host "Opening dashboards..." -ForegroundColor Yellow
    
    # Open Eureka Dashboard
    Write-Host "Opening Eureka Dashboard: $EUREKA_URL" -ForegroundColor Blue
    Start-Process $EUREKA_URL
    
    Start-Sleep -Seconds 2
    
    # Open Zipkin Dashboard
    Write-Host "Opening Zipkin Dashboard: $ZIPKIN_URL" -ForegroundColor Blue
    Start-Process $ZIPKIN_URL
    
    Start-Sleep -Seconds 2
    
    # Open API Gateway
    Write-Host "Opening API Gateway: $API_GATEWAY_URL" -ForegroundColor Blue
    Start-Process $API_GATEWAY_URL
    
    Write-Host ""
    Write-Host "All dashboards opened successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Available URLs:" -ForegroundColor Cyan
    Write-Host "  Eureka Dashboard:     $EUREKA_URL" -ForegroundColor Blue
    Write-Host "  Zipkin Dashboard:     $ZIPKIN_URL" -ForegroundColor Blue
    Write-Host "  API Gateway:          $API_GATEWAY_URL" -ForegroundColor Blue
    Write-Host "  Config Server:        $CONFIG_URL" -ForegroundColor Blue
    
} catch {
    Write-Host "Error getting Minikube IP. Make sure Minikube is running." -ForegroundColor Red
    Write-Host "Run: minikube start" -ForegroundColor Yellow
}
