#!/bin/bash
# Rollback script for Chapter 1
# Demonstrates how to quickly rollback a deployment

set -e

NAMESPACE=${NAMESPACE:-production}
DEPLOYMENT=${DEPLOYMENT:-checkout-service}

echo "🔄 Rolling back deployment: $DEPLOYMENT in namespace: $NAMESPACE"
echo ""

# Check if deployment exists
if ! kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE" &>/dev/null; then
    echo "❌ Deployment $DEPLOYMENT not found in namespace $NAMESPACE"
    exit 1
fi

# Show current status
echo "📊 Current deployment status:"
kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE"
echo ""

# Show rollout history
echo "📜 Rollout history:"
kubectl rollout history deployment/"$DEPLOYMENT" -n "$NAMESPACE"
echo ""

# Confirm rollback
read -p "Do you want to rollback to the previous version? (yes/no): " -r
echo
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Rollback cancelled."
    exit 0
fi

# Perform rollback
echo "⏪ Rolling back..."
kubectl rollout undo deployment/"$DEPLOYMENT" -n "$NAMESPACE"

# Watch the rollback progress
echo ""
echo "👀 Watching rollback progress..."
kubectl rollout status deployment/"$DEPLOYMENT" -n "$NAMESPACE"

# Show final status
echo ""
echo "✅ Rollback complete!"
echo ""
echo "📊 Final deployment status:"
kubectl get deployment "$DEPLOYMENT" -n "$NAMESPACE"
echo ""
echo "📦 Pod status:"
kubectl get pods -n "$NAMESPACE" -l app="$DEPLOYMENT"

echo ""
echo "💡 Tip: To rollback to a specific revision, use:"
echo "   kubectl rollout undo deployment/$DEPLOYMENT --to-revision=<revision> -n $NAMESPACE"
