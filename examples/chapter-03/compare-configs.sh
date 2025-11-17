#!/bin/bash
# Script to compare configurations between environments
# Chapter 3: "It Works on My Machine"

set -e

STAGING_NS=${STAGING_NS:-staging}
PRODUCTION_NS=${PRODUCTION_NS:-production}
SERVICE_NAME=${SERVICE_NAME:-notification-service}

echo "🔍 Comparing configurations for ${SERVICE_NAME}"
echo ""

# Function to get config
get_config() {
    local namespace=$1
    local resource=$2
    local name=$3
    
    kubectl get "${resource}" "${name}" -n "${namespace}" -o yaml 2>/dev/null || echo "Not found"
}

# Compare ConfigMaps
echo "📋 ConfigMaps:"
echo "=============="
echo ""
echo "Staging:"
kubectl get configmap notification-config -n ${STAGING_NS} -o jsonpath='{.data}' 2>/dev/null | jq . || echo "Not found"

echo ""
echo "Production:"
kubectl get configmap notification-config -n ${PRODUCTION_NS} -o jsonpath='{.data}' 2>/dev/null | jq . || echo "Not found"

echo ""
echo "---"
echo ""

# Compare Secrets (names only, not values)
echo "🔐 Secrets (keys only, not values):"
echo "===================================="
echo ""
echo "Staging secrets:"
kubectl get secret notification-secrets -n ${STAGING_NS} -o jsonpath='{.data}' 2>/dev/null | jq 'keys' || echo "Not found"

echo ""
echo "Production secrets:"
kubectl get secret notification-secrets -n ${PRODUCTION_NS} -o jsonpath='{.data}' 2>/dev/null | jq 'keys' || echo "Not found"

echo ""
echo "---"
echo ""

# Compare Deployment specs
echo "🚀 Deployment Differences:"
echo "=========================="
echo ""

# Replica count
STAGING_REPLICAS=$(kubectl get deployment ${SERVICE_NAME} -n ${STAGING_NS} -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "N/A")
PROD_REPLICAS=$(kubectl get deployment ${SERVICE_NAME} -n ${PRODUCTION_NS} -o jsonpath='{.spec.replicas}' 2>/dev/null || echo "N/A")

echo "Replicas:"
echo "  Staging:    ${STAGING_REPLICAS}"
echo "  Production: ${PROD_REPLICAS}"

# Image tags
STAGING_IMAGE=$(kubectl get deployment ${SERVICE_NAME} -n ${STAGING_NS} -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "N/A")
PROD_IMAGE=$(kubectl get deployment ${SERVICE_NAME} -n ${PRODUCTION_NS} -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null || echo "N/A")

echo ""
echo "Images:"
echo "  Staging:    ${STAGING_IMAGE}"
echo "  Production: ${PROD_IMAGE}"

# Resources
echo ""
echo "Resources:"
echo "  Staging:"
kubectl get deployment ${SERVICE_NAME} -n ${STAGING_NS} -o jsonpath='{.spec.template.spec.containers[0].resources}' 2>/dev/null | jq . || echo "    Not found"

echo "  Production:"
kubectl get deployment ${SERVICE_NAME} -n ${PRODUCTION_NS} -o jsonpath='{.spec.template.spec.containers[0].resources}' 2>/dev/null | jq . || echo "    Not found"

echo ""
echo "---"
echo ""

# Summary
echo "📊 Summary:"
echo "==========="
echo ""

# Check if critical configs exist
check_resource() {
    local namespace=$1
    local resource=$2
    local name=$3
    
    if kubectl get "${resource}" "${name}" -n "${namespace}" &>/dev/null; then
        echo "✅"
    else
        echo "❌"
    fi
}

echo "| Resource | Staging | Production |"
echo "|----------|---------|------------|"
echo "| ConfigMap | $(check_resource ${STAGING_NS} configmap notification-config) | $(check_resource ${PRODUCTION_NS} configmap notification-config) |"
echo "| Secret | $(check_resource ${STAGING_NS} secret notification-secrets) | $(check_resource ${PRODUCTION_NS} secret notification-secrets) |"
echo "| Deployment | $(check_resource ${STAGING_NS} deployment ${SERVICE_NAME}) | $(check_resource ${PRODUCTION_NS} deployment ${SERVICE_NAME}) |"
echo "| Service | $(check_resource ${STAGING_NS} service ${SERVICE_NAME}) | $(check_resource ${PRODUCTION_NS} service ${SERVICE_NAME}) |"

echo ""
echo "💡 Tip: Use 'kubectl diff' to see detailed differences:"
echo "   kubectl diff -k notification-service/overlays/staging"
echo "   kubectl diff -k notification-service/overlays/production"
