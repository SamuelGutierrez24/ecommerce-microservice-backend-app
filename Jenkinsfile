// Jenkinsfile
pipeline {
    agent any // Assumes agent has git, and will have kubectl after setup

    environment {
        APP_DEPLOYMENTS_NAMESPACE = "default" // Changed to default namespace
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
        KUBECTL_PATH = "/usr/local/bin/kubectl" // Define a path for kubectl
    }

    stages {
        stage('Setup Kubectl') {
            steps {
                script {
                    echo "Checking for kubectl..."
                    // Correctly check if kubectl exists and is executable
                    def kubectlExists = sh(script: "command -v ${env.KUBECTL_PATH} >/dev/null 2>&1 && ${env.KUBECTL_PATH} version --client --short >/dev/null 2>&1", returnStatus: true) == 0
                    if (kubectlExists) {
                        echo "kubectl already installed and functional."
                        sh "${env.KUBECTL_PATH} version --client"
                    } else {
                        echo "kubectl not found or not functional. Attempting to install..."
                        // Since the container runs as root (runAsUser: 0 in jenkins-deployment.yml)
                        // we should be able to install it to /usr/local/bin
                        sh "curl -LO \"https://dl.k8s.io/release/\$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl\""
                        sh "chmod +x kubectl"
                        sh "mv kubectl ${env.KUBECTL_PATH}"
                        echo "kubectl installation attempted. Verifying..."
                        sh "${env.KUBECTL_PATH} version --client"
                    }
                }
            }
        }

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
                        echo "Deploying applications to Minikube in namespace: ${env.APP_DEPLOYMENTS_NAMESPACE}..."

                        echo "Applying manifest: ${env.ZIPKIN_MANIFEST}..."
                        sh "${env.KUBECTL_PATH} apply -f ${env.ZIPKIN_MANIFEST} -n ${env.APP_DEPLOYMENTS_NAMESPACE}" // Assuming namespace is in YAML or using default/current

                        echo "Applying manifest: ${env.SERVICE_DISCOVERY_MANIFEST}..."
                        sh "${env.KUBECTL_PATH} apply -f ${env.SERVICE_DISCOVERY_MANIFEST} -n ${env.APP_DEPLOYMENTS_NAMESPACE}"
                        echo "Describing Service Discovery deployment..."
                        sh "${env.KUBECTL_PATH} describe deployment service-discovery -n ${env.APP_DEPLOYMENTS_NAMESPACE}"
                        echo "Getting all pods in namespace ${env.APP_DEPLOYMENTS_NAMESPACE}..."
                        sh "${env.KUBECTL_PATH} get pods -n ${env.APP_DEPLOYMENTS_NAMESPACE} -o wide --show-labels"
                        echo "Waiting for Service Discovery (label: ${env.SERVICE_DISCOVERY_LABEL}) to be ready in namespace ${env.APP_DEPLOYMENTS_NAMESPACE}..."
                        sh "${env.KUBECTL_PATH} wait --for=condition=ready pod -l ${env.SERVICE_DISCOVERY_LABEL} -n ${env.APP_DEPLOYMENTS_NAMESPACE} --timeout=${env.MINIKUBE_TIMEOUT}"

                        echo "Applying manifest: ${env.CLOUD_CONFIG_MANIFEST}..."
                        sh "${env.KUBECTL_PATH} apply -f ${env.CLOUD_CONFIG_MANIFEST} -n ${env.APP_DEPLOYMENTS_NAMESPACE}"
                        echo "Waiting for Cloud Config (label: ${env.CLOUD_CONFIG_LABEL}) to be ready in namespace ${env.APP_DEPLOYMENTS_NAMESPACE}..."
                        sh "${env.KUBECTL_PATH} wait --for=condition=ready pod -l ${env.CLOUD_CONFIG_LABEL} -n ${env.APP_DEPLOYMENTS_NAMESPACE} --timeout=${env.MINIKUBE_TIMEOUT}"
                        
                        echo "Applying manifest: ${env.API_GATEWAY_MANIFEST}..."
                        sh "${env.KUBECTL_PATH} apply -f ${env.API_GATEWAY_MANIFEST} -n ${env.APP_DEPLOYMENTS_NAMESPACE}"

                        echo "Deploying other business services..."
                        def businessManifests = env.BUSINESS_SERVICES_MANIFESTS.split(',')
                        for (manifest in businessManifests) {
                            echo "Applying Kubernetes manifest: ${manifest}"
                            sh "${env.KUBECTL_PATH} apply -f ${manifest.trim()} -n ${env.APP_DEPLOYMENTS_NAMESPACE}"
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
                    sh "${env.KUBECTL_PATH} get pods --all-namespaces -o wide"
                    sh "${env.KUBECTL_PATH} get services --all-namespaces -o wide"

                    echo "Checking rollout status of deployments in namespace ${env.APP_DEPLOYMENTS_NAMESPACE}..."
                    def deploymentNames = env.ALL_APP_DEPLOYMENT_NAMES.split(',')
                    for (depName in deploymentNames) {
                        def deployment = depName.trim()
                        echo "Checking rollout status for deployment: ${deployment}"
                        // The || true is to prevent pipeline failure if a specific deployment isn't found or status fails, logging a warning instead.
                        sh "${env.KUBECTL_PATH} rollout status deployment/${deployment} -n ${env.APP_DEPLOYMENTS_NAMESPACE} --timeout=${env.MINIKUBE_TIMEOUT} || echo \\\"Warning: Could not get rollout status for deployment ${deployment} in namespace ${env.APP_DEPLOYMENTS_NAMESPACE}, or it timed out.\\\""
                    }

                    echo "Attempting to retrieve Minikube IP and service URLs..."
                    // Note: 'minikube ip' will likely not work inside the Jenkins pod running in Minikube.
                    // This step might fail or return an IP not useful for external access from your machine.
                    // For in-cluster communication, services use their Kubernetes service names.
                    try {
                        // Check if minikube cli is available, if not, skip this.
                        // This is a placeholder, as minikube CLI is likely not in the jenkins/jenkins:lts image.
                        def minikubeCliExists = sh(script: 'which minikube || true', returnStatus: true) == 0
                        if (minikubeCliExists) {
                            def minikubeIp = sh(script: 'minikube ip', returnStdout: true).trim()
                            if (minikubeIp) {
                                echo "Minikube IP (attempted): ${minikubeIp}"
                            } else {
                                echo "Could not determine Minikube IP via 'minikube ip' command."
                            }
                        } else {
                             echo "Minikube CLI not found in agent. Skipping 'minikube ip'."
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
