# Chapter 3: "It Works on My Machine"

## Overview

Sarah faces the classic "works in staging but not production" problem. This chapter covers:

- Environment parity and configuration drift
- Configuration management with Kustomize
- Proper separation of config from code
- ConfigMaps vs Secrets
- Configuration validation in applications
- The twelve-factor app methodology

## Prerequisites

- Kubernetes cluster (local or cloud)
- kubectl with kustomize (built-in since kubectl 1.14)
- Basic understanding of ConfigMaps and Secrets
- Optional: `jq` for JSON processing
- Optional: `yq` for YAML processing

## Files in This Directory

### Kustomize Structure
```
notification-service/
├── base/
│   ├── deployment.yaml        # Base deployment
│   ├── service.yaml           # Service definition
│   ├── configmap.yaml         # Base ConfigMap
│   └── kustomization.yaml     # Base kustomization
└── overlays/
    ├── staging/
    │   ├── configmap.yaml     # Staging-specific config
    │   ├── secrets.yaml       # Staging secrets
    │   └── kustomization.yaml # Staging overlay
    └── production/
        ├── configmap.yaml     # Production-specific config
        ├── secrets.yaml       # Production secrets
        └── kustomization.yaml # Production overlay
```

### Scripts
- `deploy.sh` - Automated deployment script
- `test.sh` - Automated test suite
- `compare-configs.sh` - Compare configurations between environments

### Application Code
- `sample-app-with-config-validation.py` - Example app with config validation

### Documentation
- `deployment-checklist.md` - Comprehensive deployment checklist

## Quick Start

### Option 1: Automated Deployment

```bash
# Deploy to staging
./deploy.sh staging

# Deploy to production
./deploy.sh production
```

### Option 2: Manual Deployment with Kustomize

```bash
# Preview what will be deployed to staging
kubectl kustomize notification-service/overlays/staging

# Deploy to staging
kubectl apply -k notification-service/overlays/staging

# Verify deployment
kubectl get pods -n staging -l app=notification-service
```

## Learning Objectives

After completing this chapter, you should understand:

- ✅ Why "works on my machine" problems occur
- ✅ How to manage configuration with Kustomize
- ✅ The difference between ConfigMaps and Secrets
- ✅ How to validate configuration in applications
- ✅ Best practices for environment parity
- ✅ How to prevent configuration drift

See full documentation in the comprehensive README above.

---

**Total Files:** 16 (10 YAML configs, 3 scripts, 1 Python app, 2 docs)

**Online access:** [View examples on GitHub](https://github.com/BahaTanvir/devops-guide-book/tree/main/examples/chapter-03)
