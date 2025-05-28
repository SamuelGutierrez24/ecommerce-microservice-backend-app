# Monitor Ecommerce Microservices deployment
param(
    [int]$RefreshInterval = 10
)

Write-Host "Starting Ecommerce Microservices Monitor..." -ForegroundColor Green
Write-Host "Refresh interval: $RefreshInterval seconds" -ForegroundColor Yellow
Write-Host "Press Ctrl+C to stop monitoring" -ForegroundColor Yellow
Write-Host ""

function Show-Status {
    Clear-Host
    Write-Host "Ecommerce Microservices - Live Monitor" -ForegroundColor Green
    Write-Host "Last updated: $(Get-Date)" -ForegroundColor Gray
    Write-Host "="*60 -ForegroundColor Gray
    
    try {
        # Check namespace
        $namespaceExists = kubectl get namespace ecommerce-microservices --no-headers 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Host "Namespace 'ecommerce-microservices' not found!" -ForegroundColor Red
            return
        }
        
        Write-Host "Pods Status:" -ForegroundColor Cyan
        kubectl get pods -n ecommerce-microservices --no-headers | ForEach-Object {
            $fields = $_ -split '\s+'
            $name = $fields[0]
            $ready = $fields[1]
            $status = $fields[2]
            $restarts = $fields[3]
            $age = $fields[4]
            
            $color = switch ($status) {
                "Running" { "Green" }
                "Pending" { "Yellow" }
                "ContainerCreating" { "Yellow" }
                "Init:0/2" { "Yellow" }
                "Init:1/2" { "Yellow" }
                "PodInitializing" { "Yellow" }
                default { "Red" }
            }
            
            Write-Host "  $name" -NoNewline
            Write-Host " | " -NoNewline -ForegroundColor Gray
            Write-Host "$ready" -NoNewline -ForegroundColor $color
            Write-Host " | " -NoNewline -ForegroundColor Gray
            Write-Host "$status" -NoNewline -ForegroundColor $color
            Write-Host " | Restarts: $restarts | Age: $age" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "Services Status:" -ForegroundColor Cyan
        kubectl get services -n ecommerce-microservices --no-headers | ForEach-Object {
            $fields = $_ -split '\s+'
            $name = $fields[0]
            $type = $fields[1]
            $clusterIp = $fields[2]
            $externalIp = $fields[3]
            $ports = $fields[4]
            $age = $fields[5]
            
            Write-Host "  $name" -NoNewline
            Write-Host " | " -NoNewline -ForegroundColor Gray
            Write-Host "$type" -NoNewline -ForegroundColor Blue
            Write-Host " | Ports: $ports | Age: $age" -ForegroundColor Gray
        }
        
        # Show recent events
        Write-Host ""
        Write-Host "Recent Events:" -ForegroundColor Cyan
        $events = kubectl get events -n ecommerce-microservices --sort-by='.lastTimestamp' --no-headers 2>$null | Select-Object -Last 5
        if ($events) {
            $events | ForEach-Object {
                $fields = $_ -split '\s+', 6
                $lastSeen = $fields[0]
                $type = $fields[1]
                $reason = $fields[2]
                $object = $fields[3]
                $message = $fields[5]
                
                $color = switch ($type) {
                    "Normal" { "Green" }
                    "Warning" { "Yellow" }
                    default { "Red" }
                }
                
                Write-Host "  $lastSeen" -NoNewline -ForegroundColor Gray
                Write-Host " | " -NoNewline -ForegroundColor Gray
                Write-Host "$type" -NoNewline -ForegroundColor $color
                Write-Host " | $reason | $object" -ForegroundColor Gray
            }
        } else {
            Write-Host "  No recent events" -ForegroundColor Gray
        }
        
        # Show URLs if Minikube is running
        try {
            $MINIKUBE_IP = minikube ip 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host ""
                Write-Host "Quick Access URLs:" -ForegroundColor Cyan
                Write-Host "  Eureka: http://${MINIKUBE_IP}:30761" -ForegroundColor Blue
                Write-Host "  API Gateway: http://${MINIKUBE_IP}:30080" -ForegroundColor Blue
                Write-Host "  Zipkin: http://${MINIKUBE_IP}:30411" -ForegroundColor Blue
            }
        } catch {
            # Ignore minikube errors
        }
        
    } catch {
        Write-Host "Error retrieving status: $($_.Exception.Message)" -ForegroundColor Red
    }
    
    Write-Host ""
    Write-Host "Next update in $RefreshInterval seconds..." -ForegroundColor Gray
}

# Main monitoring loop
try {
    while ($true) {
        Show-Status
        Start-Sleep -Seconds $RefreshInterval
    }
} catch {
    Write-Host ""
    Write-Host "Monitoring stopped." -ForegroundColor Yellow
}
