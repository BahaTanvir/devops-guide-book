#!/bin/bash
# Cleanup script to remove all test resources
# Use this to clean up after working with examples

set -e

echo "🧹 Cleaning up DevOps Guide example resources..."
echo ""
echo "⚠️  WARNING: This will delete:"
echo "   - Local kind cluster 'devops-learning'"
echo "   - All Kubernetes resources in current context"
echo "   - Terraform state in example directories"
echo ""
read -p "Are you sure you want to continue? (yes/no): " -r
echo

if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

# Delete kind cluster
echo "🗑️  Deleting kind cluster..."
if kind get clusters 2>/dev/null | grep -q "devops-learning"; then
    kind delete cluster --name devops-learning
    echo "✓ Kind cluster deleted"
else
    echo "○ No kind cluster found"
fi

# Clean up Terraform states
echo ""
echo "🗑️  Cleaning up Terraform states..."
find examples/chapter-* -name "terraform.tfstate*" -o -name ".terraform" | while read -r path; do
    rm -rf "$path"
    echo "✓ Removed: $path"
done

# Clean up temporary files
echo ""
echo "🗑️  Cleaning up temporary files..."
find examples -name "*.tmp" -o -name ".DS_Store" -o -name "tmp_*" | while read -r path; do
    rm -rf "$path"
    echo "✓ Removed: $path"
done

echo ""
echo "✅ Cleanup complete!"
echo ""
echo "To start fresh, run:"
echo "  kind create cluster --name devops-learning --config common/kind-config.yaml"
