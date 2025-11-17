#!/bin/bash
# Deployment script for Chapter 3
# "It Works on My Machine"

set -e

ENVIRONMENT=${1:-staging}
DRY_RUN=${DRY_RUN:-false}

if [ "$ENVIRONMENT" != "staging" ] && [ "$ENVIRONMENT" != "production" ]; then
    echo "❌ Invalid environment: ${ENVIRONMENT}"
    echo "Usage: ./deploy.sh [staging|production]"
    exit 1
fi

echo "🚀 Deploying notification-service to ${ENVIRONMENT}"
echo ""

# Pre-deployment checks
echo "🔍 Pre-deployment checks..."
echo ""

# Check if kustomize is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl not found"
    exit 1
fi

# Check if kubectl can connect to cluster
if ! kubectl cluster-info &> /dev/null; then
    echo "❌ Cannot connect to Kubernetes cluster"
    exit 1
fi

# Create namespace if it doesn't exist
NAMESPACE=${ENVIRONMENT}
if ! kubectl get namespace ${NAMESPACE} &> /dev/null; then
    echo "📦 Creating namespace: ${NAMESPACE}"
    kubectl create namespace ${NAMESPACE}
fi

# Validate kustomization
echo "✓ Validating kustomization..."
kubectl kustomize notification-service/overlays/${ENVIRONMENT} > /dev/null

# Show what will be deployed
echo ""
echo "📄 Resources to be deployed:"
kubectl kustomize notification-service/overlays/${ENVIRONMENT} | grep -E "^(kind|name):" | paste - - | sed 's/kind: //' | sed 's/  name: / - /'

echo ""
read -p "Continue with deployment? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Deployment cancelled"
    exit 0
fi

# Deploy
echo ""
echo "📦 Deploying..."

if [ "$DRY_RUN" = "true" ]; then
    echo "(Dry run mode)"
    kubectl apply -k notification-service/overlays/${ENVIRONMENT} --dry-run=server
else
    kubectl apply -k notification-service/overlays/${ENVIRONMENT}
fi

echo ""
echo "⏳ Waiting for deployment to complete..."
kubectl rollout status deployment/notification-service -n ${NAMESPACE} --timeout=5m

# Post-deployment validation
echo ""
echo "🔍 Post-deployment validation..."

# Check pods
POD_COUNT=$(kubectl get pods -n ${NAMESPACE} -l app=notification-service --field-selector=status.phase=Running --no-headers | wc -l)
DESIRED_COUNT=$(kubectl get deployment notification-service -n ${NAMESPACE} -o jsonpath='{.spec.replicas}')

echo "✓ Pods running: ${POD_COUNT}/${DESIRED_COUNT}"

# Check if pods are ready
READY_COUNT=$(kubectl get deployment notification-service -n ${NAMESPACE} -o jsonpath='{.status.readyReplicas}')
echo "✓ Pods ready: ${READY_COUNT}/${DESIRED_COUNT}"

# Check configuration
echo ""
echo "🔧 Configuration check:"
kubectl get configmap notification-config -n ${NAMESPACE} -o jsonpath='{.data}' | jq .
echo ""

# Check secrets exist (but don't show values)
echo "🔐 Secrets check:"
kubectl get secret notification-secrets -n ${NAMESPACE} -o jsonpath='{.data}' | jq 'keys'

# Test health endpoint
echo ""
echo "🏥 Testing health endpoint..."
kubectl port-forward -n ${NAMESPACE} svc/notification-service 8080:80 &
PF_PID=$!
sleep 3

HEALTH_STATUS=$(curl -s http://localhost:8080/health | jq -r '.status' || echo "failed")

kill $PF_PID 2>/dev/null || true
wait $PF_PID 2>/dev/null || true

if [ "$HEALTH_STATUS" = "healthy" ]; then
    echo "✅ Health check passed"
else
    echo "⚠️  Health check failed or timed out"
fi

# Summary
echo ""
echo "================================"
echo "✅ Deployment Complete!"
echo "================================"
echo ""
echo "Environment: ${ENVIRONMENT}"
echo "Namespace: ${NAMESPACE}"
echo "Replicas: ${READY_COUNT}/${DESIRED_COUNT}"
echo ""
echo "💡 Next steps:"
echo "   - Check logs: kubectl logs -f deployment/notification-service -n ${NAMESPACE}"
echo "   - Port forward: kubectl port-forward -n ${NAMESPACE} svc/notification-service 8080:80"
echo "   - Compare envs: ./compare-configs.sh"
echo "   - Rollback: kubectl rollout undo deployment/notification-service -n ${NAMESPACE}"
