#!/bin/bash
# Deployment script for Chapter 1
# Safely deploys with validation and monitoring

set -e

NAMESPACE=${NAMESPACE:-production}
MANIFEST=${1:-deployment-v1.yaml}

echo "🚀 Deploying to namespace: $NAMESPACE"
echo "📄 Using manifest: $MANIFEST"
echo ""

# Pre-deployment checks
echo "🔍 Pre-deployment validation..."

# Check if namespace exists
if ! kubectl get namespace "$NAMESPACE" &>/dev/null; then
    echo "⚠️  Namespace $NAMESPACE doesn't exist. Creating it..."
    kubectl create namespace "$NAMESPACE"
fi

# Validate manifest
echo "  ✓ Validating manifest syntax..."
kubectl apply --dry-run=client -f "$MANIFEST" &>/dev/null

# Check for required secrets (if referenced in manifest)
if grep -q "secretKeyRef" "$MANIFEST"; then
    echo "  ✓ Checking for required secrets..."
    if ! kubectl get secret checkout-secrets -n "$NAMESPACE" &>/dev/null; then
        echo "  ⚠️  Secret 'checkout-secrets' not found. Creating it..."
        kubectl apply -f secret.yaml
    fi
fi

# Apply service first (if exists)
if [ -f "service.yaml" ]; then
    echo "  ✓ Applying service..."
    kubectl apply -f service.yaml
fi

echo ""
echo "✅ Pre-deployment checks passed"
echo ""

# Deploy
echo "📦 Applying deployment..."
kubectl apply -f "$MANIFEST"

echo ""
echo "👀 Watching rollout progress..."
DEPLOYMENT_NAME=$(kubectl get -f "$MANIFEST" -o jsonpath='{.metadata.name}')
kubectl rollout status deployment/"$DEPLOYMENT_NAME" -n "$NAMESPACE" --timeout=5m

echo ""
echo "✅ Deployment complete!"
echo ""

# Post-deployment validation
echo "🔍 Post-deployment validation..."

# Check pod status
echo "  📦 Pod status:"
kubectl get pods -n "$NAMESPACE" -l app=checkout-service

echo ""
echo "  📊 Deployment status:"
kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE"

# Check if all pods are ready
READY=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
DESIRED=$(kubectl get deployment "$DEPLOYMENT_NAME" -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')

if [ "$READY" = "$DESIRED" ]; then
    echo ""
    echo "✅ All pods are ready ($READY/$DESIRED)"
else
    echo ""
    echo "⚠️  Warning: Not all pods are ready ($READY/$DESIRED)"
    echo ""
    echo "Recent events:"
    kubectl get events -n "$NAMESPACE" --sort-by='.lastTimestamp' | tail -10
fi

echo ""
echo "💡 Next steps:"
echo "   - Monitor logs: kubectl logs -f deployment/$DEPLOYMENT_NAME -n $NAMESPACE"
echo "   - Check health: kubectl port-forward service/checkout-service 8080:80 -n $NAMESPACE"
echo "   - Rollback if needed: ./rollback.sh"
