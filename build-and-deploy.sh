#!/bin/bash

# Build and Deploy Script for Kubernetes
# This script builds all microservice images and loads them into Minikube

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Base directory for all projects
BASE_DIR="/home/kai/IdeaProjects/InnoProjects"

# Service definitions: name:directory:image
SERVICES=(
    "Auth Service:InnoAuthService:auth-service:latest"
    "User Service:InnoUserService:user-service:latest"
    "Order Service:InnoOrderService:order-service:latest"
    "Payment Service:InnoPaymentService:payment-service:latest"
    "API Gateway:InnoApiGatewayService:api-gateway:latest"
)

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Kubernetes Build & Deploy Script                         ║${NC}"
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo ""

# Step 1: Check if Minikube is running
echo -e "${YELLOW}[1/4] Checking Minikube status...${NC}"
if ! minikube status &> /dev/null; then
    echo -e "${RED}✗ Minikube is not running!${NC}"
    echo -e "${YELLOW}Starting Minikube...${NC}"
    minikube start
    echo -e "${GREEN}✓ Minikube started${NC}"
else
    echo -e "${GREEN}✓ Minikube is running${NC}"
fi
echo ""

# Step 2: Build Docker images
echo -e "${YELLOW}[2/4] Building Docker images...${NC}"
echo ""

for service_info in "${SERVICES[@]}"; do
    IFS=':' read -r name dir image tag <<< "$service_info"
    service_path="$BASE_DIR/$dir"
    full_image="$image:$tag"
    
    echo -e "${BLUE}Building $name...${NC}"
    
    # Check if directory exists
    if [ ! -d "$service_path" ]; then
        echo -e "${RED}✗ Directory not found: $service_path${NC}"
        echo -e "${YELLOW}  Skipping $name${NC}"
        echo ""
        continue
    fi
    
    # Check if Dockerfile exists
    if [ ! -f "$service_path/Dockerfile" ]; then
        echo -e "${RED}✗ Dockerfile not found in: $service_path${NC}"
        echo -e "${YELLOW}  Skipping $name${NC}"
        echo ""
        continue
    fi
    
    # Build the image
    echo -e "  Building $full_image from $service_path..."
    if docker build -t "$full_image" "$service_path"; then
        echo -e "${GREEN}  ✓ $name built successfully${NC}"
    else
        echo -e "${RED}  ✗ Failed to build $name${NC}"
        echo -e "${YELLOW}  Continuing with other services...${NC}"
    fi
    echo ""
done

# Step 3: Load images into Minikube
echo -e "${YELLOW}[3/4] Loading images into Minikube...${NC}"
echo ""

for service_info in "${SERVICES[@]}"; do
    IFS=':' read -r name dir image tag <<< "$service_info"
    full_image="$image:$tag"
    
    echo -e "${BLUE}Loading $name into Minikube...${NC}"
    
    # Check if image exists in Docker
    if docker image inspect "$full_image" &> /dev/null; then
        echo -e "  Loading $full_image..."
        if minikube image load "$full_image"; then
            echo -e "${GREEN}  ✓ $name loaded into Minikube${NC}"
        else
            echo -e "${RED}  ✗ Failed to load $name${NC}"
        fi
    else
        echo -e "${YELLOW}  ⚠ Image $full_image not found in Docker${NC}"
        echo -e "${YELLOW}  Skipping...${NC}"
    fi
    echo ""
done

# Step 4: Restart Kubernetes deployments
echo -e "${YELLOW}[4/4] Restarting Kubernetes deployments...${NC}"
echo ""

DEPLOYMENTS=(
    "auth-service"
    "user-service"
    "order-service"
    "payment-service"
    "api-gateway"
)

for deployment in "${DEPLOYMENTS[@]}"; do
    echo -e "${BLUE}Restarting $deployment...${NC}"
    if kubectl rollout restart deployment/"$deployment" 2>/dev/null; then
        echo -e "${GREEN}  ✓ $deployment restarted${NC}"
    else
        echo -e "${YELLOW}  ⚠ Deployment $deployment not found or already restarting${NC}"
    fi
done

echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Build & Deploy Complete!                                 ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Show pod status
echo -e "${BLUE}Current pod status:${NC}"
echo ""
kubectl get pods

echo ""
echo -e "${YELLOW}💡 To watch pods in real-time, run:${NC}"
echo -e "   ${BLUE}kubectl get pods -w${NC}"
echo ""
echo -e "${YELLOW}💡 To check logs for a specific pod, run:${NC}"
echo -e "   ${BLUE}kubectl logs <pod-name>${NC}"
echo ""
