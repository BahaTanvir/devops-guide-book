# Kubernetes Manifests

This directory contains production-ready Kubernetes YAML templates.

## Available Manifests

### Workloads
- **deployments/** - Deployment examples
- **statefulsets/** - StatefulSet examples
- **daemonsets/** - DaemonSet examples
- **jobs/** - Job and CronJob examples

### Networking
- **services/** - Service examples (ClusterIP, NodePort, LoadBalancer)
- **ingress/** - Ingress configurations
- **network-policies/** - NetworkPolicy examples

### Configuration
- **configmaps/** - ConfigMap examples
- **secrets/** - Secret examples (with placeholder values)

### Storage
- **persistent-volumes/** - PV and PVC examples
- **storage-classes/** - StorageClass configurations

### Security
- **rbac/** - RBAC configurations
- **pod-security/** - PodSecurityPolicy and Pod Security Standards
- **service-accounts/** - ServiceAccount examples

### Observability
- **monitoring/** - Prometheus ServiceMonitor examples
- **logging/** - Logging sidecar patterns

## Usage

```bash
# Apply a manifest
kubectl apply -f kubernetes-manifests/deployments/web-app.yaml

# Apply all manifests in a directory
kubectl apply -f kubernetes-manifests/deployments/

# Validate before applying
kubectl apply --dry-run=client -f manifest.yaml
```

## Best Practices

All manifests follow these practices:
- Resource requests and limits defined
- Health checks configured
- Labels and annotations for organization
- Security contexts applied
- Non-root containers
- Read-only root filesystems where possible

*Manifests coming soon...*
