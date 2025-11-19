#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
DOCKER_USERNAME=${1:-"your-docker-username"}
DOCKER_IMAGE_NAME="${DOCKER_USERNAME}/dummyrepo-mcp-hackathon"
APP_PORT=3000
KUBE_NAMESPACE="default"

echo -e "${BLUE}================================================${NC}"
echo -e "${BLUE}DummyRepo MCP Hackathon - Quick Start Script${NC}"
echo -e "${BLUE}================================================${NC}"

# Function to print colored output
print_status() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

# Check prerequisites
check_prerequisites() {
    echo -e "\n${BLUE}Checking prerequisites...${NC}"
    
    # Check Docker
    if ! command -v docker &> /dev/null; then
        print_error "Docker is not installed. Please install Docker."
        exit 1
    fi
    print_status "Docker found: $(docker --version)"
    
    # Check kubectl
    if ! command -v kubectl &> /dev/null; then
        print_error "kubectl is not installed. Please install kubectl."
        exit 1
    fi
    print_status "kubectl found: $(kubectl version --client --short)"
    
    # Check Node.js
    if ! command -v node &> /dev/null; then
        print_error "Node.js is not installed. Please install Node.js."
        exit 1
    fi
    print_status "Node.js found: $(node --version)"
    
    # Check npm
    if ! command -v npm &> /dev/null; then
        print_error "npm is not installed. Please install npm."
        exit 1
    fi
    print_status "npm found: $(npm --version)"
}

# Run tests locally
run_tests() {
    echo -e "\n${BLUE}Running tests...${NC}"
    npm ci
    if npm test -- --coverage; then
        print_status "All tests passed!"
        return 0
    else
        print_error "Tests failed!"
        return 1
    fi
}

# Build Docker image
build_docker_image() {
    echo -e "\n${BLUE}Building Docker image...${NC}"
    echo "Image name: ${DOCKER_IMAGE_NAME}:latest"
    
    if docker build -t "${DOCKER_IMAGE_NAME}:latest" .; then
        print_status "Docker image built successfully!"
        return 0
    else
        print_error "Failed to build Docker image!"
        return 1
    fi
}

# Test Docker image locally
test_docker_image() {
    echo -e "\n${BLUE}Testing Docker image locally...${NC}"
    
    # Check if container is already running
    if docker ps | grep -q "test-app"; then
        print_warning "Stopping existing container..."
        docker stop test-app
        docker rm test-app
    fi
    
    # Run container
    print_info "Starting container..."
    if docker run -d -p ${APP_PORT}:${APP_PORT} --name test-app "${DOCKER_IMAGE_NAME}:latest"; then
        sleep 3
        
        # Check if container is running
        if docker ps | grep -q "test-app"; then
            print_status "Container is running"
            
            # Test application
            print_info "Testing application..."
            if curl -s http://localhost:${APP_PORT} > /dev/null; then
                print_status "Application is responding!"
                
                # Show container info
                echo -e "${BLUE}Container Details:${NC}"
                docker inspect test-app --format='ID: {{.ID}}\nStatus: {{.State.Status}}\nImage: {{.Config.Image}}'
                
                # Show logs
                echo -e "\n${BLUE}Container Logs:${NC}"
                docker logs test-app
                
                # Cleanup
                read -p "Press Enter to stop and remove the container..."
                docker stop test-app
                docker rm test-app
                print_status "Container cleaned up"
                return 0
            else
                print_error "Application is not responding!"
                docker logs test-app
                docker stop test-app
                docker rm test-app
                return 1
            fi
        else
            print_error "Container failed to start"
            docker logs test-app 2>&1 || true
            docker rm test-app 2>&1 || true
            return 1
        fi
    else
        print_error "Failed to start container"
        return 1
    fi
}

# Check Kubernetes connectivity
check_kubernetes() {
    echo -e "\n${BLUE}Checking Kubernetes cluster...${NC}"
    
    if kubectl cluster-info > /dev/null 2>&1; then
        print_status "Connected to Kubernetes cluster"
        echo "Cluster Info:"
        kubectl cluster-info
        
        echo -e "\n${BLUE}Nodes:${NC}"
        kubectl get nodes
        return 0
    else
        print_error "Cannot connect to Kubernetes cluster!"
        print_info "Make sure Kubernetes is running (Minikube, Docker Desktop, or K3s)"
        return 1
    fi
}

# Deploy to Kubernetes
deploy_to_kubernetes() {
    echo -e "\n${BLUE}Deploying to Kubernetes...${NC}"
    
    # Backup original manifest
    cp kubernetes_manifest.yaml kubernetes_manifest.yaml.bak
    
    # Update manifest with actual username and tag
    sed "s|DOCKER_USERNAME|${DOCKER_USERNAME}|g" kubernetes_manifest.yaml.bak > kubernetes_manifest.yaml.tmp
    sed "s|IMAGE_TAG|latest|g" kubernetes_manifest.yaml.tmp > kubernetes_manifest.yaml
    rm kubernetes_manifest.yaml.tmp
    
    print_info "Updated manifest with Docker username: ${DOCKER_USERNAME}"
    
    # Apply manifest
    if kubectl apply -f kubernetes_manifest.yaml; then
        print_status "Manifest applied successfully!"
        
        # Wait for deployment
        echo -e "\n${BLUE}Waiting for deployment to be ready...${NC}"
        sleep 5
        
        if kubectl rollout status deployment/dummyrepo-deployment -n ${KUBE_NAMESPACE} --timeout=5m; then
            print_status "Deployment is ready!"
            
            # Get deployment info
            echo -e "\n${BLUE}Deployment Status:${NC}"
            kubectl get deployments -n ${KUBE_NAMESPACE}
            
            echo -e "\n${BLUE}Pods:${NC}"
            kubectl get pods -n ${KUBE_NAMESPACE}
            
            echo -e "\n${BLUE}Services:${NC}"
            kubectl get svc -n ${KUBE_NAMESPACE}
            
            # Get pod logs
            echo -e "\n${BLUE}Pod Logs:${NC}"
            kubectl logs -l app=dummyrepo -n ${KUBE_NAMESPACE} --tail=20
            
            return 0
        else
            print_error "Deployment failed to become ready!"
            kubectl describe deployment dummyrepo-deployment -n ${KUBE_NAMESPACE}
            return 1
        fi
    else
        print_error "Failed to apply manifest!"
        return 1
    fi
}

# Test Kubernetes deployment
test_kubernetes_deployment() {
    echo -e "\n${BLUE}Testing Kubernetes deployment...${NC}"
    
    print_info "Port-forwarding to service..."
    kubectl port-forward svc/dummyrepo-nodeport-service ${APP_PORT}:${APP_PORT} -n ${KUBE_NAMESPACE} &
    PF_PID=$!
    sleep 2
    
    print_info "Testing application..."
    if curl -s http://localhost:${APP_PORT} > /dev/null; then
        print_status "Application is accessible via Kubernetes!"
        print_info "Access at: http://localhost:${APP_PORT}"
        
        # Keep port-forward running
        read -p "Press Enter to stop port-forwarding..."
    else
        print_error "Cannot access application"
    fi
    
    # Kill port-forward
    kill $PF_PID 2>/dev/null || true
}

# Cleanup
cleanup_kubernetes() {
    echo -e "\n${BLUE}Cleaning up Kubernetes resources...${NC}"
    
    if kubectl delete -f kubernetes_manifest.yaml; then
        print_status "Resources deleted successfully!"
        return 0
    else
        print_error "Failed to delete resources!"
        return 1
    fi
}

# Main menu
show_menu() {
    echo -e "\n${BLUE}Select an option:${NC}"
    echo "1) Run full pipeline (tests → build → test → Kubernetes)"
    echo "2) Run tests only"
    echo "3) Build Docker image"
    echo "4) Test Docker image locally"
    echo "5) Deploy to Kubernetes"
    echo "6) Test Kubernetes deployment"
    echo "7) Cleanup Kubernetes resources"
    echo "8) Check prerequisites"
    echo "9) Exit"
    echo ""
}

# Main script
main() {
    if [ "$DOCKER_USERNAME" = "your-docker-username" ]; then
        print_warning "Please provide your Docker Hub username as argument:"
        echo "./quickstart.sh <your-docker-username>"
        exit 1
    fi
    
    check_prerequisites
    
    while true; do
        show_menu
        read -p "Enter your choice [1-9]: " choice
        
        case $choice in
            1)
                run_tests && build_docker_image && test_docker_image && check_kubernetes && deploy_to_kubernetes && test_kubernetes_deployment
                ;;
            2)
                run_tests
                ;;
            3)
                build_docker_image
                ;;
            4)
                test_docker_image
                ;;
            5)
                check_kubernetes && deploy_to_kubernetes
                ;;
            6)
                test_kubernetes_deployment
                ;;
            7)
                cleanup_kubernetes
                ;;
            8)
                check_prerequisites
                ;;
            9)
                print_status "Exiting..."
                exit 0
                ;;
            *)
                print_error "Invalid option. Please try again."
                ;;
        esac
    done
}

# Run main function
main
