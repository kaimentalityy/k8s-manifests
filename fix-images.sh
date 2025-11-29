#!/bin/bash

# Script to load Docker images into Minikube
# This fixes the ErrImageNeverPull error

set -e

echo "🔄 Loading Docker images into Minikube..."
echo ""

# List of images to load
IMAGES=(
    "auth-service:latest"
    "user-service:latest"
    "order-service:latest"
    "payment-service:latest"
    "api-gateway:latest"
)

# Check if images exist and load them
for image in "${IMAGES[@]}"; do
    echo "Checking $image..."
    if docker image inspect "$image" &> /dev/null; then
        echo "  ✓ Found locally, loading into Minikube..."
        minikube image load "$image"
        echo "  ✓ $image loaded successfully"
    else
        echo "  ✗ $image not found in local Docker"
        echo "    You need to build this image first!"
    fi
    echo ""
done

echo "✅ Image loading complete!"
echo ""
echo "Now restart your deployments:"
echo "  kubectl rollout restart deployment/auth-service"
echo "  kubectl rollout restart deployment/user-service"
echo "  kubectl rollout restart deployment/order-service"
echo "  kubectl rollout restart deployment/payment-service"
echo "  kubectl rollout restart deployment/api-gateway"
