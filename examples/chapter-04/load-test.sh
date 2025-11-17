#!/bin/bash
# Load testing script to measure resource usage
# Chapter 4: The Resource Crunch

set -e

SERVICE=${1:-notification-service}
NAMESPACE=${2:-production}
DURATION=${3:-60}

echo "🔥 Load Testing: $SERVICE in $NAMESPACE"
echo "Duration: ${DURATION}s"
echo ""

# Port forward to service
kubectl port-forward -n "$NAMESPACE" "svc/$SERVICE" 8080:80 &
PF_PID=$!
sleep 3

echo "📊 Baseline resource usage:"
kubectl top pod -n "$NAMESPACE" -l "app=$SERVICE" 2>/dev/null || echo "Metrics not available"
echo ""

echo "🚀 Starting load test..."
echo "Sending requests for ${DURATION} seconds..."

END_TIME=$(($(date +%s) + DURATION))
REQUEST_COUNT=0

while [ $(date +%s) -lt $END_TIME ]; do
    for i in {1..10}; do
        curl -s http://localhost:8080/ > /dev/null 2>&1 &
    done
    REQUEST_COUNT=$((REQUEST_COUNT + 10))
    sleep 0.1
done

wait

echo ""
echo "✅ Load test complete!"
echo "Total requests: $REQUEST_COUNT"
echo ""

echo "📊 Resource usage after load:"
kubectl top pod -n "$NAMESPACE" -l "app=$SERVICE" 2>/dev/null || echo "Metrics not available"

kill $PF_PID 2>/dev/null || true

echo ""
echo "💡 Check Prometheus for detailed metrics"
