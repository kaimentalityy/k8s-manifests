# Build and Deploy Guide

## Quick Start (Automated)

The easiest way to build and deploy everything:

```bash
cd /home/kai/IdeaProjects/InnoProjects/k8s-manifest
./build-and-deploy.sh
```

This script will:
1. ✅ Check if Minikube is running (start it if not)
2. ✅ Build all Docker images for your microservices
3. ✅ Load images into Minikube
4. ✅ Restart all Kubernetes deployments
5. ✅ Show pod status

---

## Manual Process (Step-by-Step)

If you prefer to do it manually or the automated script fails:

### Step 1: Build Docker Images

```bash
# Auth Service
cd /home/kai/IdeaProjects/InnoProjects/InnoAuthService
docker build -t auth-service:latest .

# User Service
cd /home/kai/IdeaProjects/InnoProjects/InnoUserService
docker build -t user-service:latest .

# Order Service
cd /home/kai/IdeaProjects/InnoProjects/InnoOrderService
docker build -t order-service:latest .

# Payment Service
cd /home/kai/IdeaProjects/InnoProjects/InnoPaymentService
docker build -t payment-service:latest .

# API Gateway
cd /home/kai/IdeaProjects/InnoProjects/InnoApiGateway
docker build -t api-gateway:latest .
```

### Step 2: Verify Images Were Built

```bash
docker images | grep -E "(auth-service|user-service|order-service|payment-service|api-gateway)"
```

You should see all 5 images listed.

### Step 3: Load Images into Minikube

```bash
cd /home/kai/IdeaProjects/InnoProjects/k8s-manifest

# Load each image
minikube image load auth-service:latest
minikube image load user-service:latest
minikube image load order-service:latest
minikube image load payment-service:latest
minikube image load api-gateway:latest
```

**Alternative**: Use the existing script:
```bash
./fix-images.sh
```

### Step 4: Restart Deployments

```bash
kubectl rollout restart deployment/auth-service
kubectl rollout restart deployment/user-service
kubectl rollout restart deployment/order-service
kubectl rollout restart deployment/payment-service
kubectl rollout restart deployment/api-gateway
```

**Or restart all at once**:
```bash
kubectl rollout restart deployment --all
```

### Step 5: Watch Pods Start

```bash
kubectl get pods -w
```

Press `Ctrl+C` to stop watching.

---

## Troubleshooting

### Check Build Progress

If the automated script is running, you can check its progress:

```bash
# See if the script is still running
ps aux | grep build-and-deploy

# Check Docker build processes
docker ps -a | head -20
```

### Check Individual Pod Status

```bash
# Get all pods
kubectl get pods

# Get detailed info about a specific pod
kubectl describe pod <pod-name>

# Check logs for a specific pod
kubectl logs <pod-name>

# Follow logs in real-time
kubectl logs -f <pod-name>
```

### Common Issues

#### Issue: `ErrImageNeverPull`
**Solution**: The image isn't in Minikube. Run steps 1-3 above.

#### Issue: `ImagePullBackOff` for Kafka
**Solution**: This is normal - Kafka pulls from Docker Hub. Wait a few minutes.

#### Issue: Pods stuck in `Pending`
**Solution**: Check if Minikube has enough resources:
```bash
minikube status
kubectl describe pod <pod-name>
```

#### Issue: Build fails with "Dockerfile not found"
**Solution**: Make sure you're in the correct service directory and the Dockerfile exists:
```bash
ls -la /home/kai/IdeaProjects/InnoProjects/InnoAuthService/Dockerfile
```

---

## Verify Everything is Working

### 1. Check All Pods Are Running

```bash
kubectl get pods
```

All pods should show `Running` status (except Kafka might take longer).

### 2. Check Services

```bash
kubectl get services
```

### 3. Check Ingress

```bash
kubectl get ingress
```

### 4. Test API Gateway

```bash
# Get Minikube IP
minikube ip

# Test the API (replace <minikube-ip> with actual IP)
curl http://<minikube-ip>/api/health
```

Or add to `/etc/hosts`:
```bash
echo "$(minikube ip) api.local" | sudo tee -a /etc/hosts
curl http://api.local/api/health
```

---

## Quick Commands Reference

```bash
# Start Minikube
minikube start

# Stop Minikube
minikube stop

# Delete Minikube cluster (fresh start)
minikube delete

# Apply Kubernetes manifests
kubectl apply -k overlays/dev

# Delete all resources
kubectl delete -k overlays/dev

# Get all resources
kubectl get all

# Watch pods
kubectl get pods -w

# Restart all deployments
kubectl rollout restart deployment --all

# Check deployment status
kubectl rollout status deployment/<deployment-name>

# Get logs from all pods of a deployment
kubectl logs -l app=<app-label> --all-containers=true

# Port forward to a service (for testing)
kubectl port-forward service/<service-name> <local-port>:<service-port>
```

---

## Development Workflow

When you make code changes:

1. **Rebuild the changed service**:
   ```bash
   cd /home/kai/IdeaProjects/InnoProjects/Inno<ServiceName>
   docker build -t <service-name>:latest .
   ```

2. **Load into Minikube**:
   ```bash
   minikube image load <service-name>:latest
   ```

3. **Restart the deployment**:
   ```bash
   kubectl rollout restart deployment/<service-name>
   ```

4. **Watch it come up**:
   ```bash
   kubectl get pods -w
   ```

**Or use the automated script** which does all of this:
```bash
cd /home/kai/IdeaProjects/InnoProjects/k8s-manifest
./build-and-deploy.sh
```

---

## Next Steps

After all pods are running:

1. ✅ Test your API endpoints
2. ✅ Check application logs
3. ✅ Verify database connections
4. ✅ Test inter-service communication
5. ✅ Monitor resource usage: `kubectl top pods` (requires metrics-server)

---

## Need Help?

- **View this guide**: `cat BUILD_GUIDE.md`
- **View migration guide**: `cat DOCKER_COMPOSE_MIGRATION.md`
- **Kubernetes docs**: https://kubernetes.io/docs/
- **Minikube docs**: https://minikube.sigs.k8s.io/docs/
