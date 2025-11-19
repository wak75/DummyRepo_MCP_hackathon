# CI/CD Pipeline Setup Guide

This guide walks you through setting up a complete CI/CD pipeline with Jenkins, Docker, and Kubernetes for the DummyRepo_MCP_hackathon project.

## Prerequisites

1. **Jenkins** installed and running (v2.361+)
2. **Docker** installed on your local machine and Jenkins server
3. **Kubernetes** cluster running locally (minikube, kind, or Docker Desktop with K8s)
4. **kubectl** CLI tool installed
5. **Git** installed
6. **Docker Hub** account
7. **curl** installed (for testing)

## Architecture Overview

```
Git Commit → Jenkins Pipeline → Build & Test → Docker Image → Push to DockerHub → Deploy to K8s
```

## Step 1: Configure Jenkins

### 1.1 Install Required Plugins

Go to **Manage Jenkins** → **Manage Plugins** and install:
- Pipeline
- GitHub Integration Plugin
- Docker Pipeline
- Kubernetes CLI Plugin

### 1.2 Create Jenkins Credentials

1. Go to **Manage Jenkins** → **Manage Credentials**
2. Add new credentials:

   **Docker Registry Credentials:**
   - Kind: Username with password
   - Username: `<your-docker-hub-username>`
   - Password: `<your-docker-hub-password-or-token>`
   - ID: `docker-username` and `docker-password`

   **Kubernetes Config:**
   - Kind: Secret file
   - File: Upload your kubeconfig file (~/.kube/config)
   - ID: `kubeconfig`

### 1.3 Create a New Pipeline Job

1. Click **New Item** → **Pipeline**
2. Name it: `DummyRepo-MCP-Pipeline`
3. In **Pipeline** section:
   - Definition: **Pipeline script from SCM**
   - SCM: **Git**
   - Repository URL: `https://github.com/wak75/DummyRepo_MCP_hackathon.git`
   - Branch: `*/main`
   - Script Path: `Jenkinsfile`
4. Click **Save**

### 1.4 Configure Build Triggers

1. Go to **Build Triggers** section
2. Enable **GitHub hook trigger for GITScm polling**
3. Or enable **Poll SCM** with schedule: `H/5 * * * *` (poll every 5 minutes)

## Step 2: Configure Local Kubernetes (Minikube/Docker Desktop)

### 2.1 Start Kubernetes Cluster

**Using Minikube:**
```bash
minikube start --driver=docker --cpus=4 --memory=4096
minikube addons enable ingress
```

**Using Docker Desktop:**
- Open Docker Desktop → Settings → Kubernetes → Enable Kubernetes
- Wait for Kubernetes to start

### 2.2 Verify Kubernetes is Running

```bash
kubectl cluster-info
kubectl get nodes
```

## Step 3: Set Up Docker Hub Access

### 3.1 Create Docker Hub Account

If you don't have one, create it at https://hub.docker.com

### 3.2 Create Personal Access Token

1. Go to Docker Hub settings → Security → New Access Token
2. Copy the token
3. Use this token as the Docker password in Jenkins credentials

### 3.3 Test Docker Login (Locally)

```bash
docker login
# Enter username and password/token when prompted
```

## Step 4: Manual Testing (Before Pipeline)

### 4.1 Build Docker Image Locally

```bash
cd DummyRepo_MCP_hackathon
docker build -t <your-docker-username>/dummyrepo-mcp-hackathon:latest .
```

### 4.2 Test Docker Image Locally

```bash
# Run the container
docker run -d -p 3000:3000 --name test-app <your-docker-username>/dummyrepo-mcp-hackathon:latest

# Test the application
curl http://localhost:3000

# Check logs
docker logs test-app

# Stop and remove
docker stop test-app
docker rm test-app
```

### 4.3 Push Image to Docker Hub

```bash
docker push <your-docker-username>/dummyrepo-mcp-hackathon:latest
```

### 4.4 Test Kubernetes Deployment

```bash
# Create a secret for Docker Hub credentials (if using private repo)
kubectl create secret docker-registry dockerhub-secret \
  --docker-server=docker.io \
  --docker-username=<your-username> \
  --docker-password=<your-token> \
  --docker-email=<your-email>

# Update kubernetes_manifest.yaml with your Docker Hub username
sed -i 's/DOCKER_USERNAME/<your-docker-username>/g' kubernetes_manifest.yaml
sed -i 's/IMAGE_TAG/latest/g' kubernetes_manifest.yaml

# Deploy to Kubernetes
kubectl apply -f kubernetes_manifest.yaml

# Check deployment status
kubectl get deployments
kubectl get pods
kubectl get services

# Port forward to access the service
kubectl port-forward svc/dummyrepo-nodeport-service 3000:3000

# In another terminal, test the app
curl http://localhost:3000

# View logs
kubectl logs -l app=dummyrepo
```

## Step 5: Run the Jenkins Pipeline

### 5.1 Trigger the Pipeline

1. Go to your Jenkins job: **DummyRepo-MCP-Pipeline**
2. Click **Build Now**
3. Monitor the build in **Build History**

### 5.2 Monitor Pipeline Execution

Watch each stage:
- **Checkout**: Git repository is cloned
- **Install Dependencies**: npm packages installed
- **Run Tests**: Jest tests executed
- **Build Docker Image**: Image built locally
- **Test Docker Image**: Container tested locally
- **Push to Docker Hub**: Image pushed to registry
- **Deploy to Kubernetes**: Application deployed to K8s cluster

### 5.3 Verify Kubernetes Deployment

```bash
# Check pod status
kubectl get pods -n default

# Check services
kubectl get svc -n default

# Check deployment
kubectl get deployment dummyrepo-deployment -n default

# Describe deployment (for debugging)
kubectl describe deployment dummyrepo-deployment -n default

# View logs from pods
kubectl logs -l app=dummyrepo -n default

# Port forward to test locally
kubectl port-forward svc/dummyrepo-nodeport-service 3000:3000 -n default

# In another terminal
curl http://localhost:3000
```

## Step 6: Accessing the Application

### Option 1: Using NodePort Service (Recommended for local)

```bash
kubectl port-forward svc/dummyrepo-nodeport-service 3000:3000
# Access at http://localhost:3000
```

### Option 2: Using Minikube Service

```bash
minikube service dummyrepo-nodeport-service
```

### Option 3: Direct Node Port Access

```bash
# Get Minikube IP
MINIKUBE_IP=$(minikube ip)
echo $MINIKUBE_IP:30000
# Access at http://<MINIKUBE_IP>:30000
```

## Step 7: Auto-Scaling Setup

The Kubernetes manifest includes a Horizontal Pod Autoscaler (HPA). To enable metrics collection:

```bash
# Install metrics-server (if not already installed)
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Check HPA status
kubectl get hpa

# Watch HPA in real-time
kubectl get hpa -w
```

## Step 8: Cleanup

### Stop Kubernetes Deployment

```bash
# Delete all resources
kubectl delete -f kubernetes_manifest.yaml

# Or delete specific namespace
kubectl delete namespace default
```

### Stop Minikube

```bash
minikube stop
minikube delete  # To completely remove
```

## Troubleshooting

### Jenkins Pipeline Fails at Docker Build

```bash
# Check if Docker daemon is running
docker ps

# Check Jenkins user has Docker permissions
sudo usermod -aG docker jenkins
sudo systemctl restart jenkins
```

### Pods Not Starting

```bash
# Check pod status and events
kubectl describe pod <pod-name>

# Check logs
kubectl logs <pod-name>

# Check image pull issues
kubectl get events --sort-by='.lastTimestamp'
```

### Image Pull Fails

```bash
# Verify image exists on Docker Hub
docker pull <your-username>/dummyrepo-mcp-hackathon:latest

# Check Kubernetes secrets
kubectl get secrets
```

### Cannot Connect to Application

```bash
# Check service is created
kubectl get svc

# Check endpoints
kubectl get endpoints

# Test internal connectivity
kubectl run test-pod --image=busybox -it -- sh
# Inside the pod: wget http://dummyrepo-service:3000
```

## Files Explanation

### Dockerfile
- Uses Node.js 18 Alpine image (lightweight)
- Installs production dependencies only
- Exposes port 3000
- Includes health check
- Runs server.js on startup

### Jenkinsfile
- **Checkout**: Pulls code from GitHub
- **Install Dependencies**: Runs `npm ci` for consistent installs
- **Run Tests**: Executes Jest tests with coverage
- **Build Docker Image**: Creates container image with build number tag
- **Test Docker Image**: Runs container locally to verify it works
- **Push to Docker Hub**: Uploads image to registry
- **Deploy to Kubernetes**: Applies manifest and rolls out deployment

### kubernetes_manifest.yaml
- **Namespace**: Isolated environment for application
- **ConfigMap**: Configuration values for the app
- **Deployment**: Manages 2 pod replicas
- **Services**: ClusterIP for internal, NodePort for external access
- **HPA**: Auto-scales pods based on CPU/memory usage
- **PodDisruptionBudget**: Ensures availability during disruptions

## Next Steps

1. Set up GitHub webhooks for automatic pipeline triggers on commits
2. Add monitoring with Prometheus and Grafana
3. Implement GitOps with ArgoCD
4. Add security scanning in pipeline (SonarQube, Trivy)
5. Set up log aggregation (ELK stack, Loki)
6. Configure ingress controller for better routing

## References

- [Jenkins Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/)
- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Dockerfile Best Practices](https://docs.docker.com/develop/develop-images/dockerfile_best-practices/)
