#!/bin/bash
# Deploy logging stack for Chapter 2
# The Mystery of the Disappearing Logs

set -e

echo "🚀 Deploying Logging Stack (Loki + Promtail)"
echo ""

# Create namespace
echo "📦 Creating logging namespace..."
kubectl create namespace logging 2>/dev/null || echo "  ℹ️  Namespace already exists"

# Deploy Loki
echo ""
echo "📊 Deploying Loki..."
kubectl apply -f loki-config.yaml

echo "  Waiting for Loki to be ready..."
kubectl wait --for=condition=ready pod -l app=loki -n logging --timeout=300s || {
    echo "  ⚠️  Loki taking longer than expected. Checking status..."
    kubectl get pods -n logging -l app=loki
}

# Deploy Promtail
echo ""
echo "📤 Deploying Promtail..."
kubectl apply -f promtail-daemonset.yaml

echo "  Waiting for Promtail DaemonSet..."
sleep 10
PROMTAIL_DESIRED=$(kubectl get daemonset promtail -n logging -o jsonpath='{.status.desiredNumberScheduled}')
PROMTAIL_READY=$(kubectl get daemonset promtail -n logging -o jsonpath='{.status.numberReady}')

echo "  Promtail pods: ${PROMTAIL_READY}/${PROMTAIL_DESIRED} ready"

# Deploy sample application (optional)
echo ""
read -p "Deploy sample application to generate logs? (y/n): " -r
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "  Deploying sample application..."
    # Create ConfigMap with the Python script
    kubectl create configmap sample-app-code \
        --from-file=sample-app-good-logging.py \
        --dry-run=client -o yaml | kubectl apply -f -
    
    kubectl apply -f sample-app-deployment.yaml
    
    echo "  Waiting for sample app..."
    kubectl wait --for=condition=ready pod -l app=sample-app --timeout=120s
fi

# Summary
echo ""
echo "================================"
echo "✅ Logging Stack Deployed!"
echo "================================"
echo ""
echo "📊 Components:"
kubectl get pods -n logging
echo ""

echo "🔍 Next steps:"
echo ""
echo "1. Access Grafana (if deployed):"
echo "   kubectl port-forward -n logging svc/grafana 3000:3000"
echo "   Then visit: http://localhost:3000"
echo ""
echo "2. Query logs directly from Loki:"
echo "   kubectl port-forward -n logging svc/loki 3100:3100"
echo "   curl 'http://localhost:3100/loki/api/v1/query' --data-urlencode 'query={namespace=\"default\"}'"
echo ""
echo "3. Check Promtail is collecting logs:"
echo "   kubectl logs -n logging daemonset/promtail"
echo ""
echo "4. Generate some test logs (if sample app deployed):"
echo "   kubectl port-forward svc/sample-app 8080:80"
echo "   curl http://localhost:8080/api/users/123"
echo ""
echo "5. View log queries examples:"
echo "   cat log-queries.md"
echo ""

echo "📚 For more information, see the Chapter 2 README"
