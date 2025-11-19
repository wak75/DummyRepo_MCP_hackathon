# DummyRepo MCP Hackathon - CI/CD Pipeline Documentation

## Overview

This repository now includes a complete **CI/CD pipeline** using **Jenkins**, **Docker**, and **Kubernetes**. The pipeline automatically:

1. ✅ Runs tests on each commit
2. 🐳 Builds a Docker image
3. 🧪 Tests the image locally
4. 📤 Pushes the image to Docker Hub
5. ☸️ Deploys to Kubernetes with 2 replicas
6. 🔄 Manages rolling updates and scaling

## Architecture

```
┌─────────────┐
│   GitHub    │
│  Repository │
└──────┬──────┘
       │ (Push/Commit)
       ▼
┌─────────────┐
│   Jenkins   │
│  Pipeline   │
└──────┬──────┘
       │
       ├─► Tests (Jest)
       │
       ├─► Build Docker Image
       │
       ├─► Test Docker Locally
       │
       ├─► Push to Docker Hub
       │
       └─► Deploy to Kubernetes
              ▼
         ┌─────────────┐
         │  K8s Pods   │
         │  (2 x Pod)  │
         └─────────────┘
              │
              └─► Services (ClusterIP + NodePort)
```

## Files Structure

```
DummyRepo_MCP_hackathon/
├── Dockerfile                    # Container image definition
├── Jenkinsfile                   # Pipeline configuration
├── kubernetes_manifest.yaml      # K8s deployment manifest
├── quickstart.sh                 # Quick start script
├── CICD_SETUP_GUIDE.md          # Detailed setup guide
├── PIPELINE_README.md           # This file
├── server.js                     # Application
├── server.test.js               # Tests
├── package.json                 # Dependencies
└── README.md                    # Original README
```

## Quick Start

### Prerequisites

- Docker installed and running
- Kubernetes cluster (Minikube, Docker Desktop, or K3s)
- kubectl configured
- Node.js and npm
- Jenkins running (for automated pipeline)
- Docker Hub account

### Option 1: Using the Quick Start Script

```bash
# Clone the repository
git clone https://github.com/wak75/DummyRepo_MCP_hackathon.git
cd DummyRepo_MCP_hackathon

# Make script executable
chmod +x quickstart.sh

# Run with your Docker Hub username
./quickstart.sh your-docker-username

# Select option 1 for full pipeline
```

### Option 2: Manual Steps

#### 1. Run Tests Locally

```bash
npm ci
npm test
```

#### 2. Build Docker Image

```bash
docker build -t your-docker-username/dummyrepo-mcp-hackathon:latest .
```

#### 3. Test Docker Image

```bash
docker run -d -p 3000:3000 --name test-app your-docker-username/dummyrepo-mcp-hackathon:latest
sleep 3
curl http://localhost:3000
docker stop test-app && docker rm test-app
```

#### 4. Push to Docker Hub

```bash
docker login
docker push your-docker-username/dummyrepo-mcp-hackathon:latest
```

#### 5. Update Kubernetes Manifest

```bash
# Replace DOCKER_USERNAME with your Docker Hub username
sed -i 's|DOCKER_USERNAME|your-docker-username|g' kubernetes_manifest.yaml
sed -i 's|IMAGE_TAG|latest|g' kubernetes_manifest.yaml
```

#### 6. Deploy to Kubernetes

```bash
kubectl apply -f kubernetes_manifest.yaml

# Monitor deployment
kubectl rollout status deployment/dummyrepo-deployment
kubectl get pods
kubectl get svc
```

#### 7. Access the Application

```bash
# Port forward
kubectl port-forward svc/dummyrepo-nodeport-service 3000:3000

# In another terminal
curl http://localhost:3000
```

## Configuration Details

### Dockerfile

The Dockerfile uses:
- **Base Image**: `node:18-alpine` (lightweight, ~150MB)
- **Port**: 3000
- **Health Check**: HTTP GET to verify container health
- **Production Dependencies**: Only production packages installed

### Jenkinsfile Stages

1. **Checkout**: Clone repository from GitHub
2. **Install Dependencies**: `npm ci` for consistent installs
3. **Run Tests**: Jest with coverage report
4. **Build Docker Image**: Create container image
5. **Test Docker Image**: Run container locally and verify
6. **Push to Docker Hub**: Upload image to registry
7. **Deploy to Kubernetes**: Apply manifest and monitor rollout

### Kubernetes Manifest Components

#### Deployment
- **Replicas**: 2 pods
- **Strategy**: Rolling update (1 max surge, 0 max unavailable)
- **Image Pull Policy**: Always (ensures latest image)
- **Health Checks**: Liveness and readiness probes
- **Resources**: CPU and memory limits

#### Services
- **ClusterIP**: Internal communication (port 3000)
- **NodePort**: External access (port 30000)

#### Auto-Scaling
- **Min Replicas**: 2
- **Max Replicas**: 5
- **CPU Trigger**: 70% utilization
- **Memory Trigger**: 80% utilization

#### Pod Disruption Budget
- **Max Unavailable**: 1 pod (ensures availability during disruptions)

## Key Features

### High Availability
- 2 pod replicas by default
- Auto-scaling up to 5 pods
- Rolling updates with zero downtime
- Pod disruption budget

### Health Management
- Liveness probe (restarts failed containers)
- Readiness probe (manages traffic routing)
- Health check in Docker container

### Resource Management
- CPU request: 100m, limit: 500m
- Memory request: 64Mi, limit: 256Mi
- Horizontal pod autoscaler

### Monitoring
- Container logs aggregation
- Deployment status tracking
- Pod event logging

## Verification Commands

### Check Deployment Status

```bash
# Get deployment info
kubectl get deployment dummyrepo-deployment
kubectl describe deployment dummyrepo-deployment

# Get pods
kubectl get pods -o wide
kubectl describe pod <pod-name>

# Get services
kubectl get svc
kubectl get endpoints
```

### View Logs

```bash
# View logs from all pods
kubectl logs -l app=dummyrepo

# View logs from specific pod
kubectl logs <pod-name>

# Stream logs
kubectl logs -f <pod-name>

# View previous logs (if pod restarted)
kubectl logs <pod-name> --previous
```

### Test Application

```bash
# Port forward
kubectl port-forward svc/dummyrepo-nodeport-service 3000:3000

# In another terminal
curl http://localhost:3000
wget -O - http://localhost:3000
```

### Scale Pods Manually

```bash
# Scale to specific number
kubectl scale deployment dummyrepo-deployment --replicas=3

# Monitor autoscaling
kubectl get hpa -w
```

## Troubleshooting

### Pod Not Starting

```bash
# Check pod status
kubectl describe pod <pod-name>

# Check events
kubectl get events --sort-by='.lastTimestamp'

# Check logs
kubectl logs <pod-name>
kubectl logs <pod-name> --previous
```

### Image Pull Issues

```bash
# Verify image exists
docker pull your-docker-username/dummyrepo-mcp-hackathon:latest

# Check image secrets
kubectl get secrets

# Describe pod for image pull errors
kubectl describe pod <pod-name>
```

### Cannot Access Application

```bash
# Check service
kubectl get svc
kubectl describe svc dummyrepo-nodeport-service

# Check endpoints
kubectl get endpoints

# Test internal connectivity
kubectl run test-pod --image=busybox -it -- sh
# Inside pod: wget http://dummyrepo-service:3000
```

### Deployment Not Ready

```bash
# Check rollout status
kubectl rollout status deployment/dummyrepo-deployment

# Rollback if needed
kubectl rollout undo deployment/dummyrepo-deployment

# Check rollout history
kubectl rollout history deployment/dummyrepo-deployment
```

## Jenkins Setup

### Create Jenkins Pipeline Job

1. Click **New Item** → **Pipeline**
2. Name: `DummyRepo-MCP-Pipeline`
3. Pipeline → Definition: **Pipeline script from SCM**
4. SCM: **Git**
5. Repository: `https://github.com/wak75/DummyRepo_MCP_hackathon.git`
6. Script Path: `Jenkinsfile`
7. Enable webhooks for automatic triggering

### Required Credentials

Add these credentials in Jenkins:

```
ID: docker-username
Type: Username with password
Username: <your-docker-hub-username>
Password: <your-docker-hub-password-or-token>

ID: docker-password
Type: Secret text
Secret: <your-docker-hub-password-or-token>

ID: kubeconfig
Type: Secret file
File: ~/.kube/config
```

### Required Jenkins Plugins

- Pipeline
- GitHub Integration
- Docker Pipeline
- Kubernetes CLI

## Cleanup

### Delete Kubernetes Resources

```bash
# Delete all resources
kubectl delete -f kubernetes_manifest.yaml

# Or delete specific resources
kubectl delete deployment dummyrepo-deployment
kubectl delete svc dummyrepo-service
kubectl delete svc dummyrepo-nodeport-service
```

### Stop Minikube

```bash
minikube stop
minikube delete  # To completely remove
```

### Remove Docker Image

```bash
docker rmi your-docker-username/dummyrepo-mcp-hackathon:latest
```

## Environment Variables

The application uses:
- `NODE_ENV`: Set to `production` in Kubernetes
- `PORT`: Set to `3000` in Kubernetes

Modify the ConfigMap in `kubernetes_manifest.yaml` to change these.

## Performance Optimization

### Container Optimization
- Alpine base image reduces size
- Multi-stage builds (can be added)
- Production dependencies only

### Kubernetes Optimization
- Resource requests and limits
- Horizontal pod autoscaling
- Rolling updates
- Pod disruption budgets

## Security Considerations

- Non-root user (can be added to Dockerfile)
- Read-only root filesystem (optional)
- Security context in pods
- Resource limits prevent denial of service

## Next Steps

1. Set up GitHub webhooks for automatic pipeline triggers
2. Implement GitOps with ArgoCD
3. Add monitoring with Prometheus and Grafana
4. Add security scanning (SonarQube, Trivy)
5. Configure log aggregation (ELK, Loki)
6. Set up ingress controller
7. Implement backup strategy

## Documentation

- **CICD_SETUP_GUIDE.md**: Detailed step-by-step setup
- **Dockerfile**: Container image definition
- **Jenkinsfile**: Pipeline stages and configuration
- **kubernetes_manifest.yaml**: Complete K8s deployment
- **quickstart.sh**: Interactive quick start script

## Support

For issues or questions:
1. Check CICD_SETUP_GUIDE.md for troubleshooting
2. Review Jenkinsfile logs
3. Check Kubernetes events: `kubectl get events`
4. View pod logs: `kubectl logs <pod-name>`

## References

- [Jenkins Documentation](https://www.jenkins.io/doc/)
- [Docker Documentation](https://docs.docker.com/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Node.js Best Practices](https://nodejs.org/en/docs/guides/)

---

**Last Updated**: November 19, 2025
**Repository**: https://github.com/wak75/DummyRepo_MCP_hackathon
