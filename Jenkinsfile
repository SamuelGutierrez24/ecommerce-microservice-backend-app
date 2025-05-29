// Jenkinsfile
pipeline {
    agent any // Assumes agent has git, kubectl, and minikube CLI

    environment {
        APP_DEPLOYMENTS_NAMESPACE = "ecommerce-microservices" // Assuming your apps deploy here, as per deploy.ps1 waits
        // Manifest files - adjust if names differ
        ZIPKIN_MANIFEST = "zipkin.yml"
        SERVICE_DISCOVERY_MANIFEST = "service-discovery.yml"
        CLOUD_CONFIG_MANIFEST = "cloud-config.yml"
        API_GATEWAY_MANIFEST = "api-gateway.yml"
        BUSINESS_SERVICES_MANIFESTS = "order-service.yml,payment-service.yml,product-service.yml,shipping-service.yml,user-service.yml,favourite-service.yml,proxy-client.yml"

        // Labels for kubectl wait commands - ensure these match the selectors in your service discovery and cloud config pods/deployments
        SERVICE_DISCOVERY_LABEL = "app=service-discovery"
        CLOUD_CONFIG_LABEL = "app=cloud-config"

        // Deployment names for rollout status check. These should match metadata.name in your Deployment YAMLs.
        // Adjust these names if they differ from the file names (sans .yml).
        ALL_APP_DEPLOYMENT_NAMES = "zipkin,service-discovery,cloud-config,api-gateway,order-service,payment-service,product-service,shipping-service,user-service,favourite-service,proxy-client"
        MINIKUBE_TIMEOUT = "5m" // Timeout for kubectl wait and rollout status
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out source code...'
                checkout scm
            }
        }

        stage('Deploy Application Manifests to Minikube') {
            steps {
                dir('k8s') { // Navigate to the directory containing manifests
                    script {
        

                        echo "Applying manifest: ${env.ZIPKIN_MANIFEST}..."
                        sh "kubectl apply -f ${env.ZIPKIN_MANIFEST}" // Assuming namespace is in YAML or using default/current

                        echo "Applying manifest: ${env.SERVICE_DISCOVERY_MANIFEST}..."
                        sh "kubectl apply -f ${env.SERVICE_DISCOVERY_MANIFEST}"
                        echo "Waiting for Service Discovery (label: ${env.SERVICE_DISCOVERY_LABEL}) to be ready in namespace ${env.APP_DEPLOYMENTS_NAMESPACE}..."
                        sh "kubectl wait --for=condition=ready pod -l ${env.SERVICE_DISCOVERY_LABEL} -n ${env.APP_DEPLOYMENTS_NAMESPACE} --timeout=${env.MINIKUBE_TIMEOUT}"

                        echo "Applying manifest: ${env.CLOUD_CONFIG_MANIFEST}..."
                        sh "kubectl apply -f ${env.CLOUD_CONFIG_MANIFEST}"
                        echo "Waiting for Cloud Config (label: ${env.CLOUD_CONFIG_LABEL}) to be ready in namespace ${env.APP_DEPLOYMENTS_NAMESPACE}..."
                        sh "kubectl wait --for=condition=ready pod -l ${env.CLOUD_CONFIG_LABEL} -n ${env.APP_DEPLOYMENTS_NAMESPACE} --timeout=${env.MINIKUBE_TIMEOUT}"
                        
                        echo "Applying manifest: ${env.API_GATEWAY_MANIFEST}..."
                        sh "kubectl apply -f ${env.API_GATEWAY_MANIFEST}"

                        echo "Deploying other business services..."
                        def businessManifests = env.BUSINESS_SERVICES_MANIFESTS.split(',')
                        for (manifest in businessManifests) {
                            echo "Applying Kubernetes manifest: ${manifest}"
                            sh "kubectl apply -f ${manifest.trim()}"
                        }
                        echo "All application manifests applied."
                    }
                }
            }
        }

        stage('Verify Deployments') {
            steps {
                script {
                    echo "Verifying deployments in Minikube..."
                    sh 'kubectl get pods --all-namespaces -o wide'
                    sh 'kubectl get services --all-namespaces -o wide'

                    echo "Checking rollout status of deployments in namespace ${env.APP_DEPLOYMENTS_NAMESPACE}..."
                    def deploymentNames = env.ALL_APP_DEPLOYMENT_NAMES.split(',')
                    for (depName in deploymentNames) {
                        def deployment = depName.trim()
                        echo "Checking rollout status for deployment: ${deployment}"
                        // The || true is to prevent pipeline failure if a specific deployment isn't found or status fails, logging a warning instead.
                        sh "kubectl rollout status deployment/${deployment} -n ${env.APP_DEPLOYMENTS_NAMESPACE} --timeout=${env.MINIKUBE_TIMEOUT} || echo \\\"Warning: Could not get rollout status for deployment ${deployment} in namespace ${env.APP_DEPLOYMENTS_NAMESPACE}, or it timed out.\\\""
                    }

                    echo "Attempting to retrieve Minikube IP and service URLs..."
                    try {
                        def minikubeIp = sh(script: 'minikube ip', returnStdout: true).trim()
                        if (minikubeIp) {
                            echo "Minikube IP: ${minikubeIp}"
                            // You can add specific service URLs here if NodePorts are known and static, e.g.:
                            // echo "API Gateway: http://${minikubeIp}:<NODE_PORT>"
                        } else {
                            echo "Could not determine Minikube IP."
                        }
                    } catch (any) {
                        echo "Could not retrieve Minikube IP: ${any.getMessage()}"
                    }
                }
            }
        }
    }

    post {
        always {
            echo 'Pipeline execution finished.'
        }
        success {
            echo 'Pipeline completed successfully!'
        }
        failure {
            echo 'Pipeline failed. Check logs for details.'
        }
    }
}
