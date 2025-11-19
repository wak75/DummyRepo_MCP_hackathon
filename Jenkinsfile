pipeline {
    agent any
    
    environment {
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_USERNAME = credentials('docker-username')
        DOCKER_PASSWORD = credentials('docker-password')
        DOCKER_IMAGE_NAME = '${DOCKER_USERNAME}/dummyrepo-mcp-hackathon'
        DOCKER_IMAGE_TAG = '${BUILD_NUMBER}'
        KUBECONFIG = credentials('kubeconfig')
    }
    
    stages {
        stage('Checkout') {
            steps {
                echo '========== Checking out code =========='
                checkout scm
            }
        }
        
        stage('Install Dependencies') {
            steps {
                echo '========== Installing dependencies =========='
                sh 'npm ci'
            }
        }
        
        stage('Run Tests') {
            steps {
                echo '========== Running tests =========='
                sh 'npm test -- --coverage'
            }
        }
        
        stage('Build Docker Image') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                echo '========== Building Docker image =========='
                sh '''
                    docker build -t ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} .
                    docker tag ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG} ${DOCKER_IMAGE_NAME}:latest
                '''
            }
        }
        
        stage('Test Docker Image') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                echo '========== Testing Docker image locally =========='
                sh '''
                    # Run container and test if it's healthy
                    CONTAINER_ID=$(docker run -d -p 3000:3000 ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG})
                    sleep 5
                    
                    # Check if container is running
                    if docker ps | grep -q $CONTAINER_ID; then
                        echo "Container is running successfully"
                        # Optional: Run health check
                        if curl -f http://localhost:3000 || true; then
                            echo "Application is responding"
                        fi
                    else
                        echo "Container failed to start"
                        exit 1
                    fi
                    
                    # Clean up
                    docker stop $CONTAINER_ID || true
                    docker rm $CONTAINER_ID || true
                '''
            }
        }
        
        stage('Push to Docker Hub') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                echo '========== Pushing image to Docker Hub =========='
                sh '''
                    echo "$DOCKER_PASSWORD" | docker login -u "$DOCKER_USERNAME" --password-stdin
                    docker push ${DOCKER_IMAGE_NAME}:${DOCKER_IMAGE_TAG}
                    docker push ${DOCKER_IMAGE_NAME}:latest
                    docker logout
                '''
            }
        }
        
        stage('Deploy to Kubernetes') {
            when {
                expression { currentBuild.result == null || currentBuild.result == 'SUCCESS' }
            }
            steps {
                echo '========== Deploying to Kubernetes =========='
                sh '''
                    # Update image tag in manifest
                    sed -i "s|IMAGE_TAG|${DOCKER_IMAGE_TAG}|g" kubernetes_manifest.yaml
                    sed -i "s|DOCKER_USERNAME|${DOCKER_USERNAME}|g" kubernetes_manifest.yaml
                    
                    # Apply the manifest
                    kubectl apply -f kubernetes_manifest.yaml
                    
                    # Wait for deployment to be ready
                    kubectl rollout status deployment/dummyrepo-deployment -n default
                    
                    # Display pods
                    kubectl get pods -n default
                '''
            }
        }
    }
    
    post {
        always {
            echo '========== Cleaning up =========='
            // Clean workspace
            cleanWs()
        }
        success {
            echo '========== Pipeline completed successfully =========='
        }
        failure {
            echo '========== Pipeline failed =========='
        }
    }
}
