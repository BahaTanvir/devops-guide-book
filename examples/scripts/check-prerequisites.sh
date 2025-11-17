#!/bin/bash
# Check if all prerequisites are installed

set -e

echo "🔍 Checking prerequisites for DevOps Guide examples..."
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Track if all checks pass
ALL_CHECKS_PASS=true

# Function to check command
check_command() {
    local cmd=$1
    local name=$2
    local required=$3
    
    if command -v "$cmd" >/dev/null 2>&1; then
        version=$($cmd --version 2>&1 | head -1)
        echo -e "${GREEN}✓${NC} $name is installed: $version"
    else
        if [ "$required" = "required" ]; then
            echo -e "${RED}✗${NC} $name is NOT installed (required)"
            ALL_CHECKS_PASS=false
        else
            echo -e "${YELLOW}○${NC} $name is NOT installed (optional)"
        fi
    fi
}

echo "📦 Core Tools:"
check_command "docker" "Docker" "required"
check_command "kubectl" "kubectl" "required"
check_command "helm" "Helm" "required"
check_command "terraform" "Terraform" "required"

echo ""
echo "🔧 Development Tools:"
check_command "git" "Git" "required"
check_command "kind" "kind" "optional"
check_command "k9s" "k9s" "optional"
check_command "kubectx" "kubectx" "optional"

echo ""
echo "☁️  Cloud CLIs:"
check_command "aws" "AWS CLI" "optional"
check_command "gcloud" "Google Cloud SDK" "optional"
check_command "az" "Azure CLI" "optional"

echo ""
echo "🔍 Checking Docker daemon..."
if docker info >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} Docker daemon is running"
else
    echo -e "${RED}✗${NC} Docker daemon is NOT running"
    ALL_CHECKS_PASS=false
fi

echo ""
echo "🔍 Checking Kubernetes cluster..."
if kubectl cluster-info >/dev/null 2>&1; then
    cluster=$(kubectl config current-context)
    echo -e "${GREEN}✓${NC} Connected to cluster: $cluster"
else
    echo -e "${YELLOW}○${NC} No Kubernetes cluster detected (you can create one with kind)"
fi

echo ""
if [ "$ALL_CHECKS_PASS" = true ]; then
    echo -e "${GREEN}✅ All required prerequisites are installed!${NC}"
    echo ""
    echo "You're ready to start working with the examples."
    exit 0
else
    echo -e "${RED}❌ Some required prerequisites are missing.${NC}"
    echo ""
    echo "Run './scripts/setup-environment.sh' to install missing tools."
    exit 1
fi
