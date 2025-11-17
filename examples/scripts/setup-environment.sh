#!/bin/bash
# Setup script for DevOps Guide examples
# This script installs all required tools for working with the book examples

set -e

echo "🚀 Setting up your DevOps learning environment..."

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Linux*)     MACHINE=Linux;;
    Darwin*)    MACHINE=Mac;;
    *)          MACHINE="UNKNOWN:${OS}"
esac

echo "📟 Detected OS: ${MACHINE}"

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install based on OS
if [ "$MACHINE" = "Mac" ]; then
    echo "🍎 Installing tools for macOS..."
    
    # Check for Homebrew
    if ! command_exists brew; then
        echo "Installing Homebrew..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    fi
    
    # Install tools
    echo "Installing DevOps tools..."
    brew install kubectl helm terraform docker kind k9s kubectx
    
elif [ "$MACHINE" = "Linux" ]; then
    echo "🐧 Installing tools for Linux..."
    
    # kubectl
    if ! command_exists kubectl; then
        echo "Installing kubectl..."
        curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
        chmod +x kubectl
        sudo mv kubectl /usr/local/bin/
    fi
    
    # helm
    if ! command_exists helm; then
        echo "Installing helm..."
        curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
    fi
    
    # terraform
    if ! command_exists terraform; then
        echo "Installing terraform..."
        wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
        echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
        sudo apt update && sudo apt install terraform
    fi
    
    # kind
    if ! command_exists kind; then
        echo "Installing kind..."
        curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
        chmod +x ./kind
        sudo mv ./kind /usr/local/bin/kind
    fi
fi

echo ""
echo "✅ Installation complete!"
echo ""
echo "📋 Installed versions:"
echo "  - kubectl: $(kubectl version --client --short 2>/dev/null || echo 'not found')"
echo "  - helm: $(helm version --short 2>/dev/null || echo 'not found')"
echo "  - terraform: $(terraform version -json 2>/dev/null | grep -oP '(?<="terraform_version":")[^"]*' || echo 'not found')"
echo "  - docker: $(docker --version 2>/dev/null || echo 'not found')"
echo "  - kind: $(kind version 2>/dev/null || echo 'not found')"
echo ""
echo "🎯 Next steps:"
echo "  1. Create a local cluster: kind create cluster --name devops-learning --config common/kind-config.yaml"
echo "  2. Verify cluster: kubectl cluster-info"
echo "  3. Start with Chapter 1 examples: cd examples/chapter-01"
echo ""
echo "Happy learning! 🚀"
