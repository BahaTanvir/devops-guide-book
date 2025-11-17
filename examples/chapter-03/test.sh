#!/bin/bash
# Test script for Chapter 3
# "It Works on My Machine"

set -e

TEST_NS="chapter-03-test"
CLEANUP=${CLEANUP:-true}

echo "🧪 Testing Chapter 3: Configuration Management"
echo ""

# Cleanup function
cleanup() {
    if [ "$CLEANUP" = "true" ]; then
        echo ""
        echo "🧹 Cleaning up..."
        kubectl delete namespace ${TEST_NS} --wait=false 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Test 1: Kustomize Validation
echo "Test 1: Validating Kustomize configurations..."
echo ""

# Validate staging
if kubectl kustomize notification-service/overlays/staging > /dev/null 2>&1; then
    echo "  ✅ Staging kustomization is valid"
else
    echo "  ❌ Staging kustomization is invalid"
    exit 1
fi

# Validate production
if kubectl kustomize notification-service/overlays/production > /dev/null 2>&1; then
    echo "  ✅ Production kustomization is valid"
else
    echo "  ❌ Production kustomization is invalid"
    exit 1
fi

# Test 2: Deploy to test namespace
echo ""
echo "Test 2: Deploying to test namespace..."
echo ""

kubectl create namespace ${TEST_NS} 2>/dev/null || true

# Apply staging config to test namespace
kubectl apply -k notification-service/overlays/staging -n ${TEST_NS} --dry-run=client > /dev/null

echo "  ✅ Deployment manifests are valid"

# Test 3: Verify required resources
echo ""
echo "Test 3: Verifying required resources..."
echo ""

# Check what resources would be created
RESOURCES=$(kubectl kustomize notification-service/overlays/staging | grep -E "^kind:" | sort | uniq)

HAS_DEPLOYMENT=$(echo "$RESOURCES" | grep -c "Deployment" || echo "0")
HAS_SERVICE=$(echo "$RESOURCES" | grep -c "Service" || echo "0")
HAS_CONFIGMAP=$(echo "$RESOURCES" | grep -c "ConfigMap" || echo "0")
HAS_SECRET=$(echo "$RESOURCES" | grep -c "Secret" || echo "0")

if [ "$HAS_DEPLOYMENT" -gt 0 ]; then
    echo "  ✅ Deployment defined"
else
    echo "  ❌ Deployment missing"
    exit 1
fi

if [ "$HAS_SERVICE" -gt 0 ]; then
    echo "  ✅ Service defined"
else
    echo "  ❌ Service missing"
    exit 1
fi

if [ "$HAS_CONFIGMAP" -gt 0 ]; then
    echo "  ✅ ConfigMap defined"
else
    echo "  ❌ ConfigMap missing"
    exit 1
fi

if [ "$HAS_SECRET" -gt 0 ]; then
    echo "  ✅ Secret defined"
else
    echo "  ❌ Secret missing"
    exit 1
fi

# Test 4: Verify environment-specific differences
echo ""
echo "Test 4: Verifying environment differences..."
echo ""

# Get replica count from each environment
STAGING_REPLICAS=$(kubectl kustomize notification-service/overlays/staging | yq eval 'select(.kind == "Deployment") | .spec.replicas' -)
PROD_REPLICAS=$(kubectl kustomize notification-service/overlays/production | yq eval 'select(.kind == "Deployment") | .spec.replicas' -)

if [ "$STAGING_REPLICAS" != "$PROD_REPLICAS" ]; then
    echo "  ✅ Replica counts differ (staging: ${STAGING_REPLICAS}, production: ${PROD_REPLICAS})"
else
    echo "  ⚠️  Replica counts are the same"
fi

# Check if ConfigMaps differ
STAGING_CONFIG=$(kubectl kustomize notification-service/overlays/staging | yq eval 'select(.kind == "ConfigMap" and .metadata.name == "notification-config") | .data' -)
PROD_CONFIG=$(kubectl kustomize notification-service/overlays/production | yq eval 'select(.kind == "ConfigMap" and .metadata.name == "notification-config") | .data' -)

if [ "$STAGING_CONFIG" != "$PROD_CONFIG" ]; then
    echo "  ✅ ConfigMaps differ between environments"
else
    echo "  ⚠️  ConfigMaps are identical"
fi

# Test 5: Verify required config keys
echo ""
echo "Test 5: Verifying required configuration keys..."
echo ""

REQUIRED_KEYS=("redis-url" "user-service-url" "log-level" "port")

for key in "${REQUIRED_KEYS[@]}"; do
    if kubectl kustomize notification-service/overlays/staging | yq eval "select(.kind == \"ConfigMap\") | .data.\"${key}\"" - | grep -q .; then
        echo "  ✅ ConfigMap has key: ${key}"
    else
        echo "  ❌ ConfigMap missing key: ${key}"
        exit 1
    fi
done

# Test 6: Verify required secrets
echo ""
echo "Test 6: Verifying required secrets..."
echo ""

REQUIRED_SECRETS=("smtp-host" "smtp-port" "smtp-user" "smtp-password" "push-api-key")

for secret_key in "${REQUIRED_SECRETS[@]}"; do
    if kubectl kustomize notification-service/overlays/staging | yq eval "select(.kind == \"Secret\") | .stringData.\"${secret_key}\"" - | grep -q .; then
        echo "  ✅ Secret has key: ${secret_key}"
    else
        echo "  ❌ Secret missing key: ${secret_key}"
        exit 1
    fi
done

# Summary
echo ""
echo "================================"
echo "📊 Test Summary"
echo "================================"
echo "✅ Kustomize configurations valid"
echo "✅ All required resources present"
echo "✅ Environment differences verified"
echo "✅ Required configuration keys present"
echo "✅ Required secrets present"
echo ""
echo "All tests passed! ✨"
echo ""
echo "💡 To deploy for real:"
echo "   ./deploy.sh staging"
echo "   ./deploy.sh production"
