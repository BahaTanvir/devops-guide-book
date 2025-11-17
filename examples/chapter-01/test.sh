#!/bin/bash
# Test script for Chapter 1 examples
# Validates that deployments work as expected

set -e

NAMESPACE="chapter-01-test"
CLEANUP=${CLEANUP:-true}

echo "🧪 Testing Chapter 1 examples..."
echo ""

# Create test namespace
echo "📦 Creating test namespace: $NAMESPACE"
kubectl create namespace "$NAMESPACE" 2>/dev/null || true

# Cleanup function
cleanup() {
    if [ "$CLEANUP" = "true" ]; then
        echo ""
        echo "🧹 Cleaning up test namespace..."
        kubectl delete namespace "$NAMESPACE" --wait=false
    fi
}
trap cleanup EXIT

# Test 1: Deploy v1 (working version)
echo ""
echo "Test 1: Deploying v1 (working version)..."
kubectl apply -f deployment-v1.yaml -n "$NAMESPACE"
kubectl apply -f service.yaml -n "$NAMESPACE"

echo "  Waiting for deployment to be ready..."
kubectl rollout status deployment/checkout-service -n "$NAMESPACE" --timeout=2m

# Verify pods are running
READY=$(kubectl get deployment checkout-service -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
DESIRED=$(kubectl get deployment checkout-service -n "$NAMESPACE" -o jsonpath='{.spec.replicas}')

if [ "$READY" = "$DESIRED" ]; then
    echo "  ✅ Test 1 passed: All pods ready ($READY/$DESIRED)"
else
    echo "  ❌ Test 1 failed: Not all pods ready ($READY/$DESIRED)"
    exit 1
fi

# Test 2: Rollback simulation
echo ""
echo "Test 2: Testing rollback..."
kubectl rollout undo deployment/checkout-service -n "$NAMESPACE"
kubectl rollout status deployment/checkout-service -n "$NAMESPACE" --timeout=2m

READY=$(kubectl get deployment checkout-service -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
if [ "$READY" = "$DESIRED" ]; then
    echo "  ✅ Test 2 passed: Rollback successful"
else
    echo "  ❌ Test 2 failed: Rollback did not complete properly"
    exit 1
fi

# Test 3: Blue-Green deployment
echo ""
echo "Test 3: Testing blue-green deployment..."
kubectl apply -f deployment-blue-green.yaml -n "$NAMESPACE"

echo "  Waiting for blue deployment..."
kubectl rollout status deployment/checkout-service-blue -n "$NAMESPACE" --timeout=2m

echo "  Waiting for green deployment..."
kubectl rollout status deployment/checkout-service-green -n "$NAMESPACE" --timeout=2m

BLUE_READY=$(kubectl get deployment checkout-service-blue -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')
GREEN_READY=$(kubectl get deployment checkout-service-green -n "$NAMESPACE" -o jsonpath='{.status.readyReplicas}')

if [ "$BLUE_READY" = "3" ] && [ "$GREEN_READY" = "3" ]; then
    echo "  ✅ Test 3 passed: Blue-green deployment successful"
else
    echo "  ❌ Test 3 failed: Blue ($BLUE_READY/3) or Green ($GREEN_READY/3) not ready"
    exit 1
fi

# Test 4: Health checks (using fixed deployment)
echo ""
echo "Test 4: Testing deployment with health checks..."
kubectl delete deployment checkout-service -n "$NAMESPACE" 2>/dev/null || true
kubectl apply -f secret.yaml -n "$NAMESPACE"
kubectl apply -f deployment-v2-fixed.yaml -n "$NAMESPACE"

echo "  Waiting for deployment with health checks..."
kubectl rollout status deployment/checkout-service -n "$NAMESPACE" --timeout=2m

# Verify health checks are configured
LIVENESS=$(kubectl get deployment checkout-service -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].livenessProbe}')
READINESS=$(kubectl get deployment checkout-service -n "$NAMESPACE" -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}')

if [ -n "$LIVENESS" ] && [ -n "$READINESS" ]; then
    echo "  ✅ Test 4 passed: Health checks configured"
else
    echo "  ❌ Test 4 failed: Health checks not configured"
    exit 1
fi

echo ""
echo "================================"
echo "✅ All tests passed!"
echo "================================"
echo ""
echo "Summary:"
echo "  - V1 deployment: ✅"
echo "  - Rollback: ✅"
echo "  - Blue-green: ✅"
echo "  - Health checks: ✅"
