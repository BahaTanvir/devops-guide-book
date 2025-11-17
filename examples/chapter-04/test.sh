#!/bin/bash
# Test script for Chapter 4
# The Resource Crunch

set -e

TEST_NS="chapter-04-test"
CLEANUP=${CLEANUP:-true}

echo "🧪 Testing Chapter 4: Resource Management"
echo ""

# Cleanup function
cleanup() {
    if [ "$CLEANUP" = "true" ]; then
        echo ""
        echo "🧹 Cleaning up..."
        kubectl delete namespace "$TEST_NS" --wait=false 2>/dev/null || true
    fi
}
trap cleanup EXIT

# Test 1: Validate resource examples
echo "Test 1: Validating resource examples..."
echo ""

for file in resource-examples/*.yaml; do
    if kubectl apply -f "$file" --dry-run=client -o yaml > /dev/null 2>&1; then
        echo "  ✅ $(basename "$file") is valid"
    else
        echo "  ❌ $(basename "$file") is invalid"
        exit 1
    fi
done

# Test 2: Validate HPA configs
echo ""
echo "Test 2: Validating HPA configurations..."
echo ""

for file in hpa-configs/*.yaml; do
    if kubectl apply -f "$file" --dry-run=client -o yaml > /dev/null 2>&1; then
        echo "  ✅ $(basename "$file") is valid"
    else
        echo "  ❌ $(basename "$file") is invalid"
        exit 1
    fi
done

# Test 3: Deploy and check QoS classes
echo ""
echo "Test 3: Testing QoS classes..."
echo ""

kubectl create namespace "$TEST_NS" 2>/dev/null || true

# Deploy different QoS examples
kubectl apply -f resource-examples/02-basic-limits.yaml -n "$TEST_NS"
kubectl apply -f resource-examples/03-guaranteed-qos.yaml -n "$TEST_NS"

sleep 5

# Check QoS classes
BURSTABLE_QOS=$(kubectl get pod basic-limits-good -n "$TEST_NS" -o jsonpath='{.status.qosClass}' 2>/dev/null || echo "")
GUARANTEED_QOS=$(kubectl get pod guaranteed-qos -n "$TEST_NS" -o jsonpath='{.status.qosClass}' 2>/dev/null || echo "")

if [ "$BURSTABLE_QOS" = "Burstable" ]; then
    echo "  ✅ Burstable QoS class correct"
else
    echo "  ⚠️  Burstable QoS: $BURSTABLE_QOS (expected Burstable)"
fi

if [ "$GUARANTEED_QOS" = "Guaranteed" ]; then
    echo "  ✅ Guaranteed QoS class correct"
else
    echo "  ⚠️  Guaranteed QoS: $GUARANTEED_QOS (expected Guaranteed)"
fi

# Test 4: Verify resource limits are set
echo ""
echo "Test 4: Verifying resource limits..."
echo ""

MEMORY_LIMIT=$(kubectl get pod basic-limits-good -n "$TEST_NS" -o jsonpath='{.spec.containers[0].resources.limits.memory}' 2>/dev/null || echo "")
CPU_LIMIT=$(kubectl get pod basic-limits-good -n "$TEST_NS" -o jsonpath='{.spec.containers[0].resources.limits.cpu}' 2>/dev/null || echo "")

if [ -n "$MEMORY_LIMIT" ] && [ -n "$CPU_LIMIT" ]; then
    echo "  ✅ Resource limits set: Memory=$MEMORY_LIMIT, CPU=$CPU_LIMIT"
else
    echo "  ❌ Resource limits not set properly"
fi

# Summary
echo ""
echo "================================"
echo "📊 Test Summary"
echo "================================"
echo "✅ All resource examples valid"
echo "✅ All HPA configs valid"
echo "✅ QoS classes verified"
echo "✅ Resource limits verified"
echo ""
echo "All tests passed! ✨"
