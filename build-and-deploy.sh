#!/bin/bash
set -e

BASE_DIR="/home/kai/IdeaProjects/InnoProjects"

SERVICES=(
    "InnoAuthService:auth-service:latest"
    "InnoUserService:user-service:latest"
    "InnoOrderService:order-service:latest"
    "InnoPaymentService:payment-service:latest"
    "InnoApiGatewayService:api-gateway:latest"
)

echo "[1] Checking Minikube..."
minikube status &>/dev/null || minikube start
echo "Minikube OK"

echo
echo "[2] Building Docker images..."
for s in "${SERVICES[@]}"; do
    IFS=':' read -r dir image tag <<< "$s"
    path="$BASE_DIR/$dir"
    full="$image:$tag"

    echo "→ $full"
    docker build -t "$full" "$path"
done

echo
echo "[3] Loading images into Minikube..."
for s in "${SERVICES[@]}"; do
    IFS=':' read -r dir image tag <<< "$s"
    full="$image:$tag"

    echo "→ $full"
    minikube image load "$full"
done

echo
echo "[4] Restarting deployments..."
DEPLOYMENTS=(
    "auth-service"
    "user-service"
    "order-service"
    "payment-service"
    "api-gateway"
)

for d in "${DEPLOYMENTS[@]}"; do
    echo "→ $d"
    kubectl rollout restart deployment/"$d" || true
done

echo
echo " Done!"
echo
kubectl get pods
