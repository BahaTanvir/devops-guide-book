# Chapter 1: The Incident That Changed Everything

## Overview

This chapter covers Sarah's first production outage - a failed deployment that takes down the checkout service. You'll learn about:

- Deployment strategies (blue-green, canary, rolling)
- Rollback procedures
- Incident response basics
- Monitoring and alerting
- Post-mortem culture

## Prerequisites

- Kubernetes cluster (local or cloud)
- kubectl configured
- Basic understanding of Kubernetes Deployments and Services

## Files in This Directory

- `deployment-v1.yaml` - Initial deployment configuration
- `deployment-v2-broken.yaml` - Broken deployment that causes the incident
- `deployment-rolling.yaml` - Rolling update deployment strategy
- `deployment-blue-green.yaml` - Blue-green deployment example
- `service.yaml` - Kubernetes service configuration
- `rollback.sh` - Script to demonstrate rollback
- `test.sh` - Automated test for this chapter's examples

## Quick Start

### 1. Deploy the Initial Version

```bash
kubectl apply -f deployment-v1.yaml
kubectl apply -f service.yaml

# Wait for deployment
kubectl rollout status deployment/checkout-service

# Test the service
kubectl port-forward service/checkout-service 8080:80
curl http://localhost:8080/health
```

### 2. Simulate the Incident (Deploy Broken Version)

```bash
kubectl apply -f deployment-v2-broken.yaml

# Watch the rollout
kubectl rollout status deployment/checkout-service

# Notice pods failing to start
kubectl get pods
kubectl describe pod <failing-pod-name>
```

### 3. Perform a Rollback

```bash
# Quick rollback to previous version
kubectl rollout undo deployment/checkout-service

# Or use the provided script
./rollback.sh

# Verify rollback
kubectl rollout status deployment/checkout-service
kubectl get pods
```

### 4. Try Different Deployment Strategies

**Rolling Update:**
```bash
kubectl apply -f deployment-rolling.yaml
kubectl rollout status deployment/checkout-service
```

**Blue-Green:**
```bash
# Deploy green (new version)
kubectl apply -f deployment-blue-green.yaml

# Switch traffic (update service selector)
kubectl patch service checkout-service -p '{"spec":{"selector":{"version":"green"}}}'

# Rollback if needed
kubectl patch service checkout-service -p '{"spec":{"selector":{"version":"blue"}}}'
```

## Learning Objectives

After working through this example, you should understand:

- ✅ How to deploy applications to Kubernetes
- ✅ Why deployments fail and how to detect failures
- ✅ Different deployment strategies and when to use them
- ✅ How to perform quick rollbacks
- ✅ The importance of health checks
- ✅ Basic incident response procedures

## Common Issues

**Pods stuck in Pending:**
- Check cluster resources: `kubectl top nodes`
- Check events: `kubectl get events --sort-by='.lastTimestamp'`

**ImagePullBackOff:**
- Verify image name and tag
- Check image registry credentials

**CrashLoopBackOff:**
- Check logs: `kubectl logs <pod-name>`
- Check resource limits
- Verify application configuration

## Cleanup

```bash
kubectl delete -f service.yaml
kubectl delete -f deployment-v1.yaml
```

## Next Steps

- Read Chapter 2 about logging and observability
- Experiment with canary deployments
- Set up monitoring and alerting
- Write a post-mortem for the simulated incident

## Additional Resources

- [Kubernetes Deployments Documentation](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/)
- [Deployment Strategies Explained](https://kubernetes.io/docs/concepts/workloads/controllers/deployment/#strategy)
- [kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)
