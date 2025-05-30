// Jenkinsfile
pipeline {
    agent any // Assumes agent has git, and will have kubectl after setup

    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'stage', 'prod'],
            description: 'Select the deployment environment'
        )
    }

    environment {
        APP_DEPLOYMENTS_NAMESPACE = "jenkins"
        SELECTED_ENV = "${params.ENVIRONMENT}"

        // Paths for tools to be installed by 'Prepare Build Environment' stage
        HOME_DIR = sh(script: 'echo $HOME', returnStdout: true).trim() // Get HOME dynamically
        JAVA_HOME_TOOLS = "${HOME_DIR}/java11"
        MAVEN_HOME_TOOLS = "${HOME_DIR}/maven"
        NODE_HOME_TOOLS = "${HOME_DIR}/nodejs"
        TOOLS_BIN_PATH = "${HOME_DIR}/bin" // For any other tools placed in $HOME/bin

        // Update PATH to include installed tools. env.PATH is the agent's original PATH.
        PATH = "${TOOLS_BIN_PATH}:${JAVA_HOME_TOOLS}/bin:${MAVEN_HOME_TOOLS}/bin:${NODE_HOME_TOOLS}/bin:${env.PATH}"
        JAVA_HOME = "${JAVA_HOME_TOOLS}" // Specifically set JAVA_HOME as well

        // Manifest files - adjust if names differ
        ZIPKIN_MANIFEST = "zipkin.yml"
        SERVICE_DISCOVERY_MANIFEST = "service-discovery.yml"
        CLOUD_CONFIG_MANIFEST = "cloud-config.yml"
        API_GATEWAY_MANIFEST = "api-gateway.yml"
        
        // All business services for 'stage'
        BUSINESS_SERVICES_MANIFESTS = "order-service.yml,payment-service.yml,product-service.yml,user-service.yml,favourite-service.yml,shipping-service.yml"
        // Specific business services for 'dev'
        DEV_SPECIFIC_BUSINESS_SERVICES_MANIFESTS = "user-service.yml,order-service.yml,product-service.yml,payment-service.yml,favourite-service.yml"

        // Labels for kubectl wait commands
        SERVICE_DISCOVERY_LABEL = "app=service-discovery"
        CLOUD_CONFIG_LABEL = "app=cloud-config"

        // Deployment names for rollout status check
        // For 'stage' - all deployments
        ALL_APP_DEPLOYMENT_NAMES = "zipkin,service-discovery,cloud-config,api-gateway,order-service,payment-service,product-service,user-service,favourite-service"
        // For 'dev' - specific deployments
        DEV_DEPLOYMENT_NAMES_TO_VERIFY = "zipkin,service-discovery,cloud-config,api-gateway,user-service,order-service,product-service,payment-service,favourite-service"
        
        MINIKUBE_TIMEOUT = "5m"
        KUBECTL_PATH = "/usr/local/bin/kubectl" // This remains from your existing setup
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

        stage('Prepare Build Environment') {
            steps {
                script {
                    echo "Preparing build environment for: ${env.SELECTED_ENV}"
                    // Ensure TOOLS_BIN_PATH exists
                    sh "mkdir -p ${env.TOOLS_BIN_PATH}"

                    // Install Java 11 for Maven
                    echo "Checking for Java 11 in ${env.JAVA_HOME_TOOLS}..."
                    if (sh(script: "[ ! -d '${env.JAVA_HOME_TOOLS}' ]", returnStatus: true) == 0) {
                        echo "Installing Java 11 to ${env.JAVA_HOME_TOOLS}..."
                        sh '''
                            cd /tmp
                            curl -L -o openjdk-11.tar.gz https://download.java.net/java/GA/jdk11/9/GPL/openjdk-11.0.2_linux-x64_bin.tar.gz
                            tar -xzf openjdk-11.tar.gz
                            mkdir -p ${JAVA_HOME_TOOLS}
                            mv jdk-11.0.2/* ${JAVA_HOME_TOOLS}/
                            rm openjdk-11.tar.gz
                            cd -
                        '''
                    } else {
                        echo "Java 11 already found at ${env.JAVA_HOME_TOOLS}"
                    }
                    echo "Verifying Java for Maven:"
                    sh "java -version" // Relies on updated PATH from environment block
                    sh "javac -version" // Relies on updated PATH

                    // Install Maven
                    echo "Checking for Maven in ${env.MAVEN_HOME_TOOLS}..."
                    if (sh(script: "[ ! -d '${env.MAVEN_HOME_TOOLS}' ]", returnStatus: true) == 0) {
                        echo "Installing Maven to ${env.MAVEN_HOME_TOOLS}..."
                        sh '''
                            cd /tmp
                            curl -sL https://archive.apache.org/dist/maven/maven-3/3.8.6/binaries/apache-maven-3.8.6-bin.tar.gz -o apache-maven-3.8.6-bin.tar.gz
                            tar -xzf apache-maven-3.8.6-bin.tar.gz
                            mkdir -p ${MAVEN_HOME_TOOLS}
                            mv apache-maven-3.8.6/* ${MAVEN_HOME_TOOLS}/
                            rm apache-maven-3.8.6-bin.tar.gz
                            cd -
                        '''
                    } else {
                        echo "Maven already found at ${env.MAVEN_HOME_TOOLS}"
                    }
                    echo "Verifying Maven:"
                    sh "mvn --version" // Relies on updated PATH

                    // Install Node.js
                    echo "Checking for Node.js in ${env.NODE_HOME_TOOLS}..."
                    if (sh(script: "[ ! -d '${env.NODE_HOME_TOOLS}' ]", returnStatus: true) == 0) {
                        echo "Installing Node.js to ${env.NODE_HOME_TOOLS}..."
                        sh '''
                            cd /tmp
                            curl -L -o node-v18.19.0-linux-x64.tar.gz https://nodejs.org/dist/v18.19.0/node-v18.19.0-linux-x64.tar.gz
                            tar -xzf node-v18.19.0-linux-x64.tar.gz
                            mkdir -p ${NODE_HOME_TOOLS}
                            mv node-v18.19.0-linux-x64/* ${NODE_HOME_TOOLS}/
                            rm node-v18.19.0-linux-x64.tar.gz
                            cd -
                        '''
                    } else {
                        echo "Node.js already found at ${env.NODE_HOME_TOOLS}"
                    }
                    echo "Verifying Node.js:"
                    sh "node --version" // Relies on updated PATH
                    sh "npm --version"  // Relies on updated PATH

                    // Install newman
                    echo "Installing/Verifying newman..."
                    sh "npm install -g newman"
                    sh "newman --version"

                    // Install Python and Locust for 'stage' environment
                    if (env.SELECTED_ENV == 'stage') {
                        echo "Verifying and installing Python for Locust (STAGE environment)..."
                        // Note: This uses apt-get, assuming a Debian-based agent.
                        // Adjust if your agent uses a different OS/package manager.
                        if (sh(script: "! command -v python3 &> /dev/null", returnStatus: true) == 0) {
                            sh "apt-get update && apt-get install -y python3 python3-pip python3-venv"
                        } else {
                            echo "Python3 already installed."
                        }
                        sh "python3 --version"
                        sh "pip3 --version"
                        echo "Installing locust..."
                        sh "python3 -m pip install --user locust --break-system-packages || pip3 install --user locust --break-system-packages"
                        // To verify locust, it needs to be in PATH or called via python3 -m locust
                        sh "python3 -m locust --version"
                    } else if (env.SELECTED_ENV == 'prod') {
                        echo "Installing GitHub CLI for PROD environment..."
                        if (sh(script: "! command -v gh &> /dev/null", returnStatus: true) == 0) {
                            echo "GitHub CLI not found. Installing..."
                            sh '''
                                curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
                                chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg
                                echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null
                                apt-get update && apt-get install -y gh
                            '''
                            sh "gh --version"
                        } else {
                            echo "GitHub CLI already installed."
                            sh "gh --version"
                        }
                    } else {
                        echo "Skipping Python/Locust and GitHub CLI installation for environment ${env.SELECTED_ENV}"
                    }

                    echo "=== BUILD ENVIRONMENT PREPARATION COMPLETE ==="
                }
            }
        }

        stage('Deploy Application Manifests to Minikube') {
            when {
                expression { return env.SELECTED_ENV == 'dev' || env.SELECTED_ENV == 'stage' || env.SELECTED_ENV == 'prod' }
            }
            steps {
                dir('k8s') {
                    script {
                        echo "Deploying for environment: ${env.SELECTED_ENV} to namespace: ${env.APP_DEPLOYMENTS_NAMESPACE}..."

                        // Common core services for dev, stage, and prod
                        echo "Applying manifest: ${env.ZIPKIN_MANIFEST}..."
                        sh "${env.KUBECTL_PATH} apply -f ${env.ZIPKIN_MANIFEST} -n ${env.APP_DEPLOYMENTS_NAMESPACE}" // Assuming namespace is in YAML or using default/current

                        echo "Applying manifest: ${env.SERVICE_DISCOVERY_MANIFEST}..."
                        sh "${env.KUBECTL_PATH} apply -f ${env.SERVICE_DISCOVERY_MANIFEST} -n ${env.APP_DEPLOYMENTS_NAMESPACE}"
                        echo "Describing Service Discovery deployment..."
                        sh "${env.KUBECTL_PATH} describe deployment service-discovery -n ${env.APP_DEPLOYMENTS_NAMESPACE}"
                        echo "Getting all pods in namespace ${env.APP_DEPLOYMENTS_NAMESPACE}..."
                        sh "${env.KUBECTL_PATH} get pods -n ${env.APP_DEPLOYMENTS_NAMESPACE} -o wide --show-labels"
                        echo "Waiting for Service Discovery (label: ${env.SERVICE_DISCOVERY_LABEL}) to be ready..."
                        sh "${env.KUBECTL_PATH} wait --for=condition=ready pod -l ${env.SERVICE_DISCOVERY_LABEL} -n ${env.APP_DEPLOYMENTS_NAMESPACE} --timeout=${env.MINIKUBE_TIMEOUT}"

                        echo "Applying manifest: ${env.CLOUD_CONFIG_MANIFEST}..."
                        sh "${env.KUBECTL_PATH} apply -f ${env.CLOUD_CONFIG_MANIFEST} -n ${env.APP_DEPLOYMENTS_NAMESPACE}"
                        echo "Waiting for Cloud Config (label: ${env.CLOUD_CONFIG_LABEL}) to be ready..."
                        sh "${env.KUBECTL_PATH} wait --for=condition=ready pod -l ${env.CLOUD_CONFIG_LABEL} -n ${env.APP_DEPLOYMENTS_NAMESPACE} --timeout=${env.MINIKUBE_TIMEOUT}"
                        
                        echo "Applying manifest: ${env.API_GATEWAY_MANIFEST}..."
                        sh "${env.KUBECTL_PATH} apply -f ${env.API_GATEWAY_MANIFEST} -n ${env.APP_DEPLOYMENTS_NAMESPACE}"

                        def businessServicesToDeploy
                        if (env.SELECTED_ENV == 'dev') {
                            echo "Deploying DEV specific business services..."
                            businessServicesToDeploy = env.DEV_SPECIFIC_BUSINESS_SERVICES_MANIFESTS.split(',')
                        } else { // stage or prod
                            echo "Deploying ALL business services for ${env.SELECTED_ENV}..."
                            businessServicesToDeploy = env.BUSINESS_SERVICES_MANIFESTS.split(',')
                        }

                        for (manifest in businessServicesToDeploy) {
                            if (manifest.trim()) {
                                echo "Applying Kubernetes manifest: ${manifest.trim()}"
                                sh "${env.KUBECTL_PATH} apply -f ${manifest.trim()} -n ${env.APP_DEPLOYMENTS_NAMESPACE}"
                            }
                        }
                        echo "All selected application manifests applied for ${env.SELECTED_ENV}."
                    }
                }
            }
        }

        stage('Run Unit and Integration Tests') {
            when {
                expression { return env.SELECTED_ENV == 'stage' || env.SELECTED_ENV == 'prod' }
            }
            steps {
                script {
                    echo "Running targeted tests for ${env.SELECTED_ENV} environment..."
                    
                    echo "Running Unit Tests in user-service..."
                    dir('user-service') {
                        sh "mvn clean test"
                    }
                    
                    echo "Running Integration Tests in product-service (skipping its unit tests)..."
                    dir('product-service') {
                        sh "mvn clean verify -DskipTests"
                    }
                    echo "Finished Unit and Integration tests for ${env.SELECTED_ENV}."
                }
            }
        }

        stage('Ejecutar Pruebas E2E') {
            when {
                anyOf {
                    expression { return env.SELECTED_ENV == 'stage' }
                    expression { return env.SELECTED_ENV == 'prod' }
                }
            }
            steps {
                script {
                    echo "Verificando que newman esté disponible (debería estar en PATH)..."
                    sh "newman --version"
            
                    echo "Ejecutando pruebas E2E desde la carpeta 'E2E test'..."
                    // Quoting 'E2E test' because of the space in the directory name
                    dir('E2E test') {
                        sh 'newman run "TestE2E.postman_collection1.json"'
                    }
                    echo "Pruebas E2E completadas."
                }
            }
        }

        stage('Ejecutar Pruebas de Carga (Locust)') {
            when {
                expression { return env.SELECTED_ENV == 'stage' }
            }
            steps {
                script {
                    echo "Verificando Python y Locust (deberían estar en PATH o accesibles)..."
                    sh "python3 --version"
                    sh "python3 -m locust --version" // Ensures locust is callable

                    echo "Ejecutando pruebas de carga con Locust desde la carpeta 'locust'..."
                    dir('locust') {
                        // Ensure locustfile.py is present
                        sh 'ls -l locustfile.py' 
                        sh '''
                            python3 -m locust -f locustfile.py --headless -u 100 -r 20 -t 30s --csv=load_test_report --html=load_test_report.html
                            echo "Pruebas de Locust completadas. Listando reportes generados:"
                            ls -la load_test_report*
                        '''
                    }
                }
            }
            post {
                always {
                    echo "Archivando reportes de Locust..."
                    archiveArtifacts artifacts: 'locust/load_test_report*.csv, locust/load_test_report*.html', allowEmptyArchive: true
                }
            }
        }

        stage('Verify Deployments') {
            when {
                expression { return env.SELECTED_ENV == 'dev' || env.SELECTED_ENV == 'stage' || env.SELECTED_ENV == 'prod' }
            }
            steps {
                script {
                    echo "Verifying deployments in Minikube for environment ${env.SELECTED_ENV}..."
                    sh "${env.KUBECTL_PATH} get pods --all-namespaces -o wide"
                    sh "${env.KUBECTL_PATH} get services --all-namespaces -o wide"

                    echo "Checking rollout status of deployments in namespace ${env.APP_DEPLOYMENTS_NAMESPACE}..."
                    def deploymentNamesList
                    if (env.SELECTED_ENV == 'dev') {
                        deploymentNamesList = env.DEV_DEPLOYMENT_NAMES_TO_VERIFY.split(',')
                    } else { // stage or prod
                        deploymentNamesList = env.ALL_APP_DEPLOYMENT_NAMES.split(',')
                    }

                    for (depName in deploymentNamesList) {
                        def deployment = depName.trim()
                        if (deployment) {
                            echo "Checking rollout status for deployment: ${deployment}"
                            sh "${env.KUBECTL_PATH} rollout status deployment/${deployment} -n ${env.APP_DEPLOYMENTS_NAMESPACE} --timeout=${env.MINIKUBE_TIMEOUT} || echo \\\"Warning: Could not get rollout status for deployment ${deployment} in namespace ${env.APP_DEPLOYMENTS_NAMESPACE}, or it timed out.\\\""
                        }
                    }
                }
            }
        }

        stage('Generar Release Notes') {
            when {
                expression { return env.SELECTED_ENV == 'prod' }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: '4feaea26-8346-4c74-9c12-c546417eadde', usernameVariable: 'GH_USER', passwordVariable: 'GH_TOKEN')]) {
                    script {                        echo "Generating Release Notes for PROD environment..."
                        def now = new Date()
                        // Format: vYEAR.MONTH.DAY.HOURMINUTE (e.g., v2023.05.15.1430)
                        def tag = "v${now.format('yyyy.MM.dd.HHmm')}"
                        def title = "🚀 Production Release ${tag}"
                        def releaseDate = now.format('MMMM dd, yyyy \'at\' HH:mm')
                        
                        // Create formatted release notes
                        def releaseNotes = """
## E-Commerce Microservices Backend - Production Release

### Release Information
- **Version:** ${tag}
- **Release Date:** ${releaseDate}
- **Environment:** Production
- **Build Number:** #${env.BUILD_NUMBER}

### Architecture Overview
This release includes the complete microservices architecture:

#### Core Infrastructure Services
- **Service Discovery** - Eureka service registry
- **Cloud Config** - Centralized configuration management
- **API Gateway** - Single entry point for all services
- **Zipkin** - Distributed tracing and monitoring

#### Business Services
- **User Service** - User management and authentication
- **Product Service** - Product catalog and inventory
- **Order Service** - Order processing and management
- **Payment Service** - Payment processing
- **Favourite Service** - User favorites management

### Quality Assurance
This release has been thoroughly tested with:
- ✅ Unit Tests (user-service)
- ✅ Integration Tests (product-service)
- ✅ End-to-End Tests (Newman/Postman)
- ✅ Load Testing (Locust)
- ✅ Kubernetes Deployment Verification

### Deployment Details
- **Platform:** Kubernetes (Minikube)
- **Namespace:** jenkins
- **Deployment Strategy:** Rolling Update
- **Health Checks:** Enabled for all services

### Monitoring & Observability
- **Tracing:** Zipkin dashboard available
- **Logs:** Centralized logging via Kubernetes
- **Metrics:** Service health monitoring

### Security
- Secure inter-service communication
- API Gateway authentication
- Environment-based configuration

"""
                        
                        sh """#!/bin/bash -e
                            echo "Current directory: \$(pwd)"
                            echo "Verifying Git and GitHub CLI versions..."
                            git --version
                            gh --version

                            echo "Configuring Git with user: Jenkins CI and email: jenkins-ci@ecommerce.com"
                            git config user.email "jenkins-ci@ecommerce.com"
                            git config user.name "Jenkins CI"
                            
                            echo "Configuring Git to use GitHub token for authentication with github.com..."
                            # This ensures git operations (like push) are authenticated via the token for github.com.
                            # It replaces https://github.com/ with https://oauth2:\${GH_TOKEN}@github.com/
                            git config --global url."https://oauth2:\${GH_TOKEN}@github.com/".insteadOf "https://github.com/"
                            
                            echo "Creating Git tag: ${tag}"
                            # Create an annotated tag with a message.
                            git tag -a "${tag}" -m "🚀 Production deployment ${tag} - ${releaseDate}"
                            
                            echo "Pushing Git tag ${tag} to remote repository 'origin'..."
                            git push origin "${tag}"
                            
                            echo "Creating formatted release notes file..."
                            cat > release_notes.md << 'EOF'
${releaseNotes}
EOF
                            
                            echo "Creating GitHub release for tag ${tag} with title '${title}'..."
                            # Export GH_TOKEN as GITHUB_TOKEN for gh CLI to pick it up.
                            # gh CLI uses GITHUB_TOKEN environment variable for authentication.
                            export GITHUB_TOKEN="\${GH_TOKEN}"
                            gh release create "${tag}" \\
                                --title "${title}" \\
                                --notes-file release_notes.md \\
                                --generate-notes \\
                                --latest
                            
                            echo "Successfully created GitHub release for tag ${tag}."
                            echo "Release URL: \$(gh release view ${tag} --web --json url --jq '.url')"
                        """
                        echo "Release notes generation stage completed for tag ${tag}."
                    }
                }
            }
        }
    }

    post {
        always {
            echo "Pipeline execution finished for environment: ${params.ENVIRONMENT}."
            echo "Limpiando espacio de trabajo..."
            catchError(buildResult: 'SUCCESS', stageResult: 'SUCCESS') {
                cleanWs()
            }
        }
        success {
            echo "Pipeline completed successfully for environment: ${params.ENVIRONMENT}!"
        }
        failure {
            echo "Pipeline failed for environment: ${params.ENVIRONMENT}. Check logs for details."
        }
    }
}
