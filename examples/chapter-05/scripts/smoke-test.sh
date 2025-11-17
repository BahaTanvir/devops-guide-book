#!/bin/bash
# Smoke tests for post-deployment validation
# Chapter 5: The Slow Release Nightmare

set -e

ENVIRONMENT=${1:-staging}
BASE_URL="https://api-${ENVIRONMENT}.example.com"

echo "🔥 Running smoke tests against: $BASE_URL"
echo ""

# Test 1: Health check
echo "Test 1: Health check..."
if curl -f -s "${BASE_URL}/health" > /dev/null; then
    echo "  ✅ Health check passed"
else
    echo "  ❌ Health check failed"
    exit 1
fi

# Test 2: Readiness check
echo ""
echo "Test 2: Readiness check..."
READY_STATUS=$(curl -s "${BASE_URL}/ready" | jq -r '.status')
if [ "$READY_STATUS" = "ready" ]; then
    echo "  ✅ Readiness check passed"
else
    echo "  ❌ Readiness check failed: $READY_STATUS"
    exit 1
fi

# Test 3: API endpoint test
echo ""
echo "Test 3: API endpoint test..."
if curl -f -s "${BASE_URL}/api/v1/users/1" > /dev/null; then
    echo "  ✅ API endpoint test passed"
else
    echo "  ❌ API endpoint test failed"
    exit 1
fi

# Test 4: Response time check
echo ""
echo "Test 4: Response time check..."
RESPONSE_TIME=$(curl -o /dev/null -s -w '%{time_total}' "${BASE_URL}/health")
if (( $(echo "$RESPONSE_TIME < 1.0" | bc -l) )); then
    echo "  ✅ Response time OK: ${RESPONSE_TIME}s"
else
    echo "  ⚠️  Slow response time: ${RESPONSE_TIME}s"
fi

echo ""
echo "================================"
echo "✅ All smoke tests passed!"
echo "================================"
