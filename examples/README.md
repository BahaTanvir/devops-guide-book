# Code Examples for "A Guide to DevOps Engineering"

This directory contains all the working code examples, configurations, and scripts referenced in the book.

## 📂 Directory Structure

```
examples/
├── chapter-01/ through chapter-36/  # Chapter-specific examples
├── common/                           # Shared utilities and configurations
├── labs/                            # Hands-on lab exercises
├── terraform-modules/               # Reusable Terraform modules
├── kubernetes-manifests/            # Example K8s YAML files
├── ci-cd-pipelines/                # CI/CD pipeline examples
├── monitoring-configs/              # Prometheus, Grafana configs
└── scripts/                        # Helper scripts and tools
```

## 🚀 Getting Started

### Prerequisites

Before running the examples, ensure you have:

```bash
# Container tools
docker --version
kubectl version --client

# Infrastructure as Code
terraform --version

# Cloud CLI (choose your provider)
aws --version        # AWS
gcloud --version     # GCP
az --version         # Azure

# Other tools
helm version
git --version
```

### Setting Up Your Environment

#### Option 1: Local Kubernetes (Recommended for Learning)

```bash
# Install kind (Kubernetes in Docker)
brew install kind  # macOS
# OR
curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo mv ./kind /usr/local/bin/kind

# Create a local cluster
kind create cluster --name devops-learning --config common/kind-config.yaml

# Verify
kubectl cluster-info --context kind-devops-learning
```

#### Option 2: Cloud Provider (For Production-Like Experience)

**AWS:**
```bash
# Configure AWS credentials
aws configure

# Create EKS cluster (requires eksctl)
eksctl create cluster -f common/eks-cluster.yaml
```

**GCP:**
```bash
# Configure gcloud
gcloud init

# Create GKE cluster
gcloud container clusters create devops-learning \
  --zone us-central1-a \
  --num-nodes 3
```

### Installing Required Tools

```bash
# Run the setup script
./scripts/setup-environment.sh

# Or install manually
brew install kubectl helm terraform k9s kubectx
```

## 📖 Using the Examples

### Chapter-Specific Examples

Each chapter has its own directory with:
- **README.md** - Overview and instructions
- **Source code** - Application code if needed
- **Configurations** - YAML, HCL, or other config files
- **Scripts** - Automation scripts
- **Documentation** - Additional context

Example workflow:
```bash
# Navigate to chapter directory
cd examples/chapter-11

# Read the instructions
cat README.md

# Apply the configurations
kubectl apply -f deployment.yaml

# Clean up when done
kubectl delete -f deployment.yaml
```

### Reusable Modules

The `terraform-modules/`, `kubernetes-manifests/`, and other shared directories contain production-ready templates you can use in your own projects.

```bash
# Use a Terraform module
cd terraform-modules/vpc
terraform init
terraform plan
```

### Hands-On Labs

The `labs/` directory contains structured exercises:

```bash
cd labs/lab-01-first-deployment
./run-lab.sh
```

## 🔧 Common Utilities

### Helper Scripts

Located in `scripts/`:
- `setup-environment.sh` - Install all required tools
- `check-prerequisites.sh` - Verify your setup
- `create-test-cluster.sh` - Quick cluster setup
- `cleanup-resources.sh` - Remove all test resources
- `test-examples.sh` - Validate all code examples

### Shared Configurations

Located in `common/`:
- Kubernetes cluster configs
- Common ConfigMaps and Secrets templates
- Shared Helm values files
- Docker Compose setups

## 🧪 Testing Examples

Before using examples, test they work:

```bash
# Test a specific chapter
./scripts/test-chapter.sh 11

# Test all examples (takes a while!)
./scripts/test-all-examples.sh

# Lint configurations
./scripts/lint-configs.sh
```

## 🛡️ Safety Guidelines

### ⚠️ Important Notes

1. **Never use production credentials** - All examples use test/demo credentials
2. **Set cost alerts** - If using cloud providers, set up billing alerts
3. **Clean up resources** - Always run cleanup scripts after testing
4. **Isolate environments** - Use separate accounts/projects for learning
5. **Review before applying** - Understand what each command does

### Cost Management

```bash
# Check estimated costs (AWS)
./scripts/estimate-aws-costs.sh

# Set up billing alerts
./scripts/setup-billing-alerts.sh

# Clean up expensive resources
./scripts/cleanup-expensive-resources.sh
```

### Security Best Practices

- ✅ All secrets use placeholder values (replace with your own)
- ✅ No hardcoded credentials in any file
- ✅ `.gitignore` configured to prevent credential leaks
- ✅ Examples use least-privilege IAM policies
- ✅ Network policies enforce isolation

## 📚 Chapter Guide

### Part I: Foundations
- **Chapter 1**: Deployment strategies, rollback procedures
- **Chapter 2**: Centralized logging with ELK stack
- **Chapter 3**: Environment parity and configuration management
- **Chapter 4**: Kubernetes resource limits and scaling
- **Chapter 5**: CI/CD pipeline optimization

### Part II: Infrastructure as Code
- **Chapter 6**: Terraform state management
- **Chapter 7**: Drift detection and reconciliation
- **Chapter 8**: Terraform module development
- **Chapter 9**: Multi-environment management
- **Chapter 10**: Cloud cost optimization

### Part III: Container Orchestration
- **Chapter 11**: Kubernetes basics - Pods, Deployments, Services
- **Chapter 12**: Kubernetes networking and Ingress
- **Chapter 13**: StatefulSets and persistent storage
- **Chapter 14**: ConfigMaps, Secrets, and Helm
- **Chapter 15**: Health checks and probes
- **Chapter 16**: Horizontal and vertical autoscaling

### Part IV: Observability and Reliability
- **Chapter 17**: Prometheus and Grafana setup
- **Chapter 18**: Alert tuning and on-call best practices
- **Chapter 19**: Distributed tracing with Jaeger
- **Chapter 20**: SLO definition and error budgets
- **Chapter 21**: Load testing and capacity planning
- **Chapter 22**: Systematic debugging methodology

### Part V: Security and Compliance
- **Chapter 23**: Container image security scanning
- **Chapter 24**: Secrets management with Vault
- **Chapter 25**: RBAC and workload identity
- **Chapter 26**: Audit logging and compliance
- **Chapter 27**: Network policies and service mesh

### Part VI: CI/CD Mastery
- **Chapter 28**: Advanced pipeline patterns
- **Chapter 29**: Testing strategies in CI/CD
- **Chapter 30**: GitOps with ArgoCD/Flux
- **Chapter 31**: Rollback strategies
- **Chapter 32**: Blue-green and canary deployments

### Part VII: Collaboration and Culture
- **Chapter 33**: Technical documentation and communication
- **Chapter 34**: On-call runbooks and playbooks
- **Chapter 35**: Automation decision frameworks
- **Chapter 36**: Career development strategies

## 🤝 Contributing Examples

Found a bug or want to improve an example?

1. Test your changes thoroughly
2. Update documentation
3. Ensure it follows best practices
4. Submit a pull request

See [CONTRIBUTING.md](../CONTRIBUTING.md) for details.

## 📋 Troubleshooting

### Common Issues

**"kubectl: command not found"**
```bash
./scripts/install-kubectl.sh
```

**"Cannot connect to Docker daemon"**
```bash
# Start Docker Desktop (macOS/Windows)
# OR on Linux:
sudo systemctl start docker
```

**"Cluster already exists"**
```bash
kind delete cluster --name devops-learning
kind create cluster --name devops-learning
```

**"Permission denied"**
```bash
chmod +x scripts/*.sh
```

### Getting Help

- Check the chapter's README.md
- Review common issues in [TROUBLESHOOTING.md](../TROUBLESHOOTING.md)
- Ask in GitHub Discussions
- Join our Discord community

## 🔗 Additional Resources

- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Terraform Documentation](https://www.terraform.io/docs/)
- [AWS Documentation](https://docs.aws.amazon.com/)
- [Docker Documentation](https://docs.docker.com/)

## 📄 License

All code examples are licensed under the MIT License - see [LICENSE](../LICENSE.md) for details.

---

**Happy Learning! 🚀**

*Remember: Breaking things in a learning environment is how you learn what NOT to do in production.*
