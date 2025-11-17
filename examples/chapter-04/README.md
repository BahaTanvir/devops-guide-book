# Chapter 4: The Resource Crunch

## Overview

Application crashes due to resource limits in Kubernetes. This chapter covers:

- Understanding resource requests and limits
- Horizontal vs vertical scaling
- CPU throttling and memory OOMKills
- Rightsizing applications
- Cost optimization strategies

## Files

### Resource Examples
- `resource-examples/01-no-limits.yaml` - Pod without resource limits (anti-pattern)
- `resource-examples/02-basic-limits.yaml` - Basic resource limits
- `resource-examples/03-guaranteed-qos.yaml` - Guaranteed QoS class (requests = limits)
- `resource-examples/04-cpu-intensive.yaml` - CPU-intensive workload configuration
- `resource-examples/05-memory-intensive.yaml` - Memory-intensive workload configuration
- `resource-examples/06-web-service-balanced.yaml` - Balanced web service resources

### HPA (Horizontal Pod Autoscaler)
- `hpa-configs/basic-hpa.yaml` - Basic HPA with CPU and memory metrics
- `hpa-configs/advanced-hpa.yaml` - Advanced HPA with custom scaling behavior

### Monitoring
- `monitoring/prometheus-alerts.yaml` - Resource-related Prometheus alerts
- `monitoring/grafana-queries.md` - Grafana dashboard queries for resource monitoring

### Scripts
- `load-test.sh` - Load testing script to trigger scaling
- `memory-profiling-app.py` - Python app with memory profiling and health checks
- `test.sh` - Automated tests for resource examples

### Configuration
- `resource-quota.yaml` - Namespace resource quotas and limit ranges

## Prerequisites

- Kubernetes cluster (1.24+)
- `kubectl` configured
- `metrics-server` installed for HPA
- `kube-state-metrics` for monitoring (optional)
- Prometheus/Grafana for alerts (optional)

## Quick Start

### 1. Deploy Examples

> **Note:** Run these commands from the `examples/chapter-04/` directory so relative paths resolve correctly.

```bash
# Deploy a resource example
kubectl apply -f resource-examples/06-web-service-balanced.yaml

# Check resource allocation
kubectl describe pod -l app=web-service

# View resource usage
kubectl top pod -l app=web-service
```

### 2. Test HPA

```bash
# Deploy basic HPA
kubectl apply -f hpa-configs/basic-hpa.yaml

# Generate load
./load-test.sh

# Watch scaling
kubectl get hpa -w
```

### 3. Deploy Monitoring Alerts

```bash
# Create monitoring namespace
kubectl create namespace monitoring

# Deploy alerts (requires Prometheus)
kubectl apply -f monitoring/prometheus-alerts.yaml
```

### 4. Run Memory Profiling App

```bash
# Deploy the app
kubectl apply -f - <<EOF
apiVersion: apps/v1
kind: Deployment
metadata:
  name: memory-profiling-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: memory-profiling-app
  template:
    metadata:
      labels:
        app: memory-profiling-app
    spec:
      containers:
      - name: app
        image: python:3.11-slim
        command: ["python", "/app/app.py"]
        volumeMounts:
        - name: app-code
          mountPath: /app
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
      volumes:
      - name: app-code
        configMap:
          name: memory-profiling-app-code
---
apiVersion: v1
kind: ConfigMap
metadata:
  name: memory-profiling-app-code
data:
  app.py: |
$(cat memory-profiling-app.py | sed 's/^/    /')
EOF

# Test the memory leak endpoint
kubectl port-forward deployment/memory-profiling-app 5000:5000 &
curl http://localhost:5000/leak?mb=100
curl http://localhost:5000/memory
```

### 5. Run Test Suite

```bash
# Run all tests
./test.sh

# Should output:
# ✅ All tests passed!
```

## Learning Objectives

After completing these examples, you will understand:

1. **Resource Management**
   - Difference between requests (scheduling) and limits (enforcement)
   - How CPU is throttled vs how memory causes OOMKills
   - QoS classes: Guaranteed, Burstable, BestEffort

2. **Horizontal Pod Autoscaling**
   - Configure HPA based on CPU/memory metrics
   - Use advanced scaling behaviors (stabilization windows, policies)
   - Prevent scaling flapping

3. **Monitoring & Alerting**
   - Set up alerts for OOMKills and CPU throttling
   - Monitor resource usage with Prometheus
   - Create dashboards for capacity planning

4. **Best Practices**
   - Always set resource requests and limits
   - Use resource quotas to protect namespaces
   - Right-size based on P95 usage, not averages
   - Leave headroom for spikes (2x limits vs requests)

## Common Issues

### Issue: Pods stuck in Pending
```bash
# Check if node has capacity
kubectl describe node

# Look for: "Insufficient cpu" or "Insufficient memory"
```

**Solution:** Reduce resource requests or add more nodes

### Issue: Pods getting OOMKilled
```bash
# Check OOMKill events
kubectl describe pod <pod-name> | grep -i oom

# Check actual memory usage
kubectl top pod <pod-name>
```

**Solution:** Increase memory limits or optimize application

### Issue: HPA not scaling
```bash
# Check metrics server
kubectl top nodes

# Check HPA status
kubectl describe hpa <hpa-name>
```

**Solution:** Ensure metrics-server is installed and pods have resource requests

### Issue: CPU throttling degrading performance
```bash
# Check throttling metrics in Prometheus
rate(container_cpu_cfs_throttled_seconds_total[5m])
```

**Solution:** Increase CPU limits or optimize code

## Additional Resources

- [Kubernetes Resource Management](https://kubernetes.io/docs/concepts/configuration/manage-resources-containers/)
- [HPA Walkthrough](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale-walkthrough/)
- [QoS Classes](https://kubernetes.io/docs/tasks/configure-pod-container/quality-service-pod/)
- [Resource Quotas](https://kubernetes.io/docs/concepts/policy/resource-quotas/)
