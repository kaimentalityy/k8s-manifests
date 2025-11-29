# Docker Compose Migration Guide

## Current Situation

You have a `docker-compose.yaml` file that runs:
- Infrastructure: Kafka, MongoDB, PostgreSQL (4 instances), Redis
- Application Services: auth-service, user-service, order-service, payment-service, api-gateway
- Minikube container

You're now migrating to Kubernetes, so you need to decide what to keep in Docker Compose.

---

## ⚠️ The Problem You're Facing

**Error**: `ErrImageNeverPull` on all application service pods

**Cause**: Your Kubernetes manifests use `imagePullPolicy: Never`, which means Kubernetes expects images to be in Minikube's Docker daemon, but they're only in your host Docker.

**Solution**: Load images into Minikube (see below)

---

## 🎯 Recommended Approach: Hybrid Setup

### Keep in Docker Compose:
- ❌ **Remove** all application services (they'll run in Kubernetes)
- ✅ **Keep** infrastructure services (easier for local development)
- ❌ **Remove** the minikube container (use native Minikube)

### Run in Kubernetes:
- ✅ All application services
- ✅ All infrastructure (Kafka, PostgreSQL, MongoDB, Redis)

### Why This Approach?
1. **Consistency**: Your Kubernetes manifests already define all infrastructure
2. **Production Parity**: Test exactly what will run in production
3. **Simplicity**: One deployment method (Kubernetes)

---

## 🔧 Fix Your Current Deployment

### Step 1: Check if Docker Images Exist

```bash
docker images | grep -E "(auth-service|user-service|order-service|payment-service|api-gateway)"
```

### Step 2: Build Images if Missing

If images don't exist, you need to build them. Based on your docker-compose.yaml:

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

### Step 3: Load Images into Minikube

```bash
cd /home/kai/IdeaProjects/InnoProjects/k8s-manifest

# Run the fix script
./fix-images.sh

# OR manually load each image
minikube image load auth-service:latest
minikube image load user-service:latest
minikube image load order-service:latest
minikube image load payment-service:latest
minikube image load api-gateway:latest
```

### Step 4: Restart Deployments

```bash
kubectl rollout restart deployment/auth-service
kubectl rollout restart deployment/user-service
kubectl rollout restart deployment/order-service
kubectl rollout restart deployment/payment-service
kubectl rollout restart deployment/api-gateway
```

### Step 5: Watch Pods Come Up

```bash
kubectl get pods -w
```

Wait until all pods show `Running` status.

---

## 📝 Update Your docker-compose.yaml

### Option A: Remove All Services (Full Kubernetes)

Create a minimal `docker-compose.yaml` or remove it entirely:

```yaml
# docker-compose.yaml - MINIMAL VERSION
version: '3.8'

# Keep only if you want to run infrastructure locally for development
# Otherwise, delete this file and use Kubernetes for everything

networks:
  innonetwork:
    driver: bridge
    name: ${DOCKER_NETWORK_NAME:-innonetwork}

volumes:
  postgres_auth_data:
  postgres_user_data:
  postgres_order_data:
  postgres_payment_data:
  kafka_data:
  mongo_data:
  redis_data:
```

### Option B: Keep Infrastructure Only (Hybrid)

```yaml
# docker-compose.yaml - INFRASTRUCTURE ONLY
version: '3.8'

services:
  # Keep infrastructure services for local development
  kafka:
    image: confluentinc/cp-kafka:7.6.0
    container_name: kafka
    restart: always
    ports:
      - "29092:29092"
    environment:
      KAFKA_NODE_ID: 1
      KAFKA_PROCESS_ROLES: broker,controller
      KAFKA_CONTROLLER_QUORUM_VOTERS: 1@kafka:9093
      KAFKA_LISTENERS: PLAINTEXT://0.0.0.0:29092,PLAINTEXT_HOST://0.0.0.0:9092,CONTROLLER://:9093
      KAFKA_ADVERTISED_LISTENERS: PLAINTEXT://kafka:29092,PLAINTEXT_HOST://localhost:9092
      KAFKA_LISTENER_SECURITY_PROTOCOL_MAP: CONTROLLER:PLAINTEXT,PLAINTEXT:PLAINTEXT,PLAINTEXT_HOST:PLAINTEXT
      KAFKA_INTER_BROKER_LISTENER_NAME: PLAINTEXT
      KAFKA_CONTROLLER_LISTENER_NAMES: CONTROLLER
      KAFKA_LOG_DIRS: /var/lib/kafka/data
      KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_REPLICATION_FACTOR: 1
      KAFKA_TRANSACTION_STATE_LOG_MIN_ISR: 1
      CLUSTER_ID: MkU3OEVBNTcwNTJENDM2Qk
    volumes:
      - kafka_data:/var/lib/kafka/data

  mongodb:
    image: mongo:6
    container_name: mongodb
    restart: always
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: secret
    ports:
      - "27017:27017"
    volumes:
      - mongo_data:/data/db

  postgres_auth:
    image: postgres:15
    container_name: postgres_auth
    environment:
      POSTGRES_DB: auth_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: "17052007"
    ports:
      - "5433:5432"
    volumes:
      - postgres_auth_data:/var/lib/postgresql/data

  postgres_user:
    image: postgres:15
    container_name: postgres_user
    environment:
      POSTGRES_DB: user_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: "17052007"
    ports:
      - "5434:5432"
    volumes:
      - postgres_user_data:/var/lib/postgresql/data

  postgres_order:
    image: postgres:15
    container_name: postgres_order
    environment:
      POSTGRES_DB: order_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: "17052007"
    ports:
      - "5435:5432"
    volumes:
      - postgres_order_data:/var/lib/postgresql/data

  postgres_payment:
    image: postgres:15
    container_name: postgres_payment
    environment:
      POSTGRES_DB: payment_db
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: "17052007"
    ports:
      - "5436:5432"
    volumes:
      - postgres_payment_data:/var/lib/postgresql/data

  redis:
    image: redis:7-alpine
    container_name: redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data

  # REMOVED: All application services (run in Kubernetes instead)
  # REMOVED: minikube container (use native Minikube)

volumes:
  postgres_auth_data:
  postgres_user_data:
  postgres_order_data:
  postgres_payment_data:
  kafka_data:
  mongo_data:
  redis_data:
```

---

## 🚀 Recommended Workflow

### For Full Kubernetes (Recommended):

1. **Stop Docker Compose** (if running):
   ```bash
   docker-compose down
   ```

2. **Deploy to Kubernetes**:
   ```bash
   cd /home/kai/IdeaProjects/InnoProjects/k8s-manifest
   kubectl apply -k overlays/dev
   ```

3. **Load Images** (if needed):
   ```bash
   ./fix-images.sh
   ```

4. **Restart Deployments**:
   ```bash
   kubectl rollout restart deployment --all
   ```

### For Hybrid Approach:

1. **Start Infrastructure via Docker Compose**:
   ```bash
   docker-compose up -d kafka mongodb postgres_auth postgres_user postgres_order postgres_payment redis
   ```

2. **Update Kubernetes Manifests** to point to localhost infrastructure
   - Change `kafka:9092` to `host.minikube.internal:29092`
   - Change `postgres-auth:5432` to `host.minikube.internal:5433`
   - etc.

3. **Deploy Services to Kubernetes**:
   ```bash
   kubectl apply -k overlays/dev
   ```

---

## ⚡ Quick Fix Right Now

Run these commands to fix your current deployment:

```bash
cd /home/kai/IdeaProjects/InnoProjects/k8s-manifest

# 1. Load images into Minikube
./fix-images.sh

# 2. Restart all deployments
kubectl rollout restart deployment --all

# 3. Watch pods
kubectl get pods -w
```

---

## 🎯 My Recommendation

**Use Full Kubernetes** (Option A):

1. Remove application services from `docker-compose.yaml`
2. Keep infrastructure in `docker-compose.yaml` only if you want to run it locally sometimes
3. For now, run everything in Kubernetes to match production
4. Fix the image loading issue with `./fix-images.sh`

This gives you:
- ✅ Production parity
- ✅ Single deployment method
- ✅ Easier to test and debug
- ✅ Better learning experience with Kubernetes
