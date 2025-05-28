# Ecommerce Microservices - Kubernetes Deployment

This directory contains Kubernetes manifests to deploy the ecommerce microservices application on Minikube.

## Prerequisites

1. **Minikube** installed and running
2. **kubectl** configured to use Minikube context
3. Docker images built and available (your custom images with tag `lastest`)

## Quick Start

### 1. Start Minikube
```powershell
minikube start --driver=docker --memory=8192 --cpus=4
```

### 2. Deploy the Application
```powershell
.\k8s\deploy.ps1
```

### 3. Check Status
```powershell
.\k8s\status.ps1
```

### 4. Clean Up (when done)
```powershell
.\k8s\undeploy.ps1
```

## Architecture Overview

The deployment includes the following services:

### Core Infrastructure Services
- **Zipkin** (Port 9411): Distributed tracing
- **Service Discovery** (Port 8761): Eureka server for service registration
- **Cloud Config** (Port 9296): Centralized configuration management

### Application Services
- **API Gateway** (Port 8080): Main entry point, routing requests to services
- **Order Service** (Port 8300): Order management
- **Payment Service** (Port 8400): Payment processing
- **Product Service** (Port 8500): Product catalog
- **Shipping Service** (Port 8600): Shipping management
- **User Service** (Port 8700): User management
- **Favourite Service** (Port 8800): User favorites
- **Proxy Client** (Port 8900): Client proxy service

## Service Dependencies

The services are deployed in a specific order to ensure dependencies are met:

1. **Zipkin** - Independent tracing service
2. **Service Discovery** - Must be available before other services register
3. **Cloud Config** - Must be available before services request configuration
4. **API Gateway** - Depends on Service Discovery and Cloud Config
5. **Business Services** - Depend on Service Discovery, Cloud Config, and potentially each other

## Kubernetes Resources

Each service includes:
- **Deployment**: Manages the pod lifecycle
- **Service**: Provides network access (NodePort for external access)
- **Init Containers**: Wait for dependencies (Eureka and Config Server)
- **Health Checks**: Liveness and readiness probes
- **Resource Limits**: Memory and CPU constraints

## Network Configuration

All services are deployed in the `ecommerce-microservices` namespace and use:
- **Internal DNS**: Services communicate using Kubernetes DNS (e.g., `service-discovery:8761`)
- **NodePort Services**: External access via Minikube IP on specific ports (30xxx range)

## Environment Variables

Each service is configured with:
- `SPRING_PROFILES_ACTIVE=dev`
- Zipkin tracing URL
- Eureka client configuration
- Config server URL

## Accessing Services

After deployment, access services using the Minikube IP:

### Get Minikube IP
```powershell
minikube ip
```

### Main Dashboards
- **Eureka Dashboard**: `http://<minikube-ip>:30761`
- **Zipkin Dashboard**: `http://<minikube-ip>:30411`
- **API Gateway**: `http://<minikube-ip>:30080`

### Business Services
All business services are accessible via the API Gateway or directly:
- Through API Gateway: `http://<minikube-ip>:30080/<service-name>/**`
- Direct access: `http://<minikube-ip>:30xxx/<service-name>`

## Troubleshooting

### Check Pod Status
```powershell
kubectl get pods -n ecommerce-microservices
```

### View Pod Logs
```powershell
kubectl logs -f deployment/<service-name> -n ecommerce-microservices
```

### Describe Pod (for debugging)
```powershell
kubectl describe pod <pod-name> -n ecommerce-microservices
```

### Check Events
```powershell
kubectl get events -n ecommerce-microservices --sort-by='.lastTimestamp'
```

### Common Issues

1. **Pods stuck in Pending**: Check resource availability
2. **Services not registering with Eureka**: Check Service Discovery logs
3. **Configuration issues**: Check Cloud Config logs
4. **Init containers failing**: Check if dependencies are ready

### Resource Requirements

Minimum recommended resources for Minikube:
- **Memory**: 8GB
- **CPU**: 4 cores
- **Disk**: 20GB

### Scaling Services

To scale a service:
```powershell
kubectl scale deployment <service-name> --replicas=2 -n ecommerce-microservices
```

### Update Image

To update a service image:
```powershell
kubectl set image deployment/<service-name> <container-name>=<new-image> -n ecommerce-microservices
```

## Files Description

- `namespace.yml`: Creates the ecommerce-microservices namespace
- `zipkin.yml`: Zipkin distributed tracing service
- `service-discovery.yml`: Eureka server for service registration
- `cloud-config.yml`: Spring Cloud Config server
- `api-gateway.yml`: API Gateway service
- `*-service.yml`: Individual microservice deployments
- `deploy.ps1`: Deployment script with proper ordering
- `undeploy.ps1`: Cleanup script
- `status.ps1`: Status checking script

## Notes

- All services use NodePort for external access in development
- Init containers ensure proper startup order
- Health checks are configured for all services
- Resource limits prevent resource exhaustion
- Services are configured to use development profiles
