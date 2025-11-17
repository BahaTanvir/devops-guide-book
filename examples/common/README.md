# Common Utilities and Configurations

This directory contains shared configurations and utilities used across multiple chapters.

## 📂 Contents

- **cluster-configs/** - Kubernetes cluster configurations for various providers
- **docker-compose/** - Docker Compose setups for local development
- **helm-values/** - Common Helm values files
- **manifests/** - Shared Kubernetes manifests
- **scripts/** - Utility scripts used by multiple chapters
- **templates/** - Configuration templates

## Cluster Configurations

### kind-config.yaml
Configuration for local Kubernetes cluster using kind (Kubernetes in Docker).

### eks-cluster.yaml
AWS EKS cluster configuration using eksctl.

### gke-cluster.yaml
GCP GKE cluster configuration.

## Usage

These files are referenced by chapter-specific examples. You generally don't need to modify them unless you're customizing your learning environment.
