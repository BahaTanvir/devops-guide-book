# Chapter 2: The Mystery of the Disappearing Logs

## Overview

Sarah discovers that critical logs are missing during debugging. This chapter covers:

- Centralized logging architecture (Loki + Promtail)
- Structured logging with JSON
- Log retention policies
- Correlation IDs and request tracing
- Log query patterns with LogQL
- Cost management for logs

## Prerequisites

- Kubernetes cluster (local or cloud)
- kubectl configured
- At least 2 GB of available memory for Loki
- Basic understanding of logs and JSON

## Files in This Directory

### Kubernetes Manifests
- `loki-config.yaml` - Loki StatefulSet and configuration
- `promtail-daemonset.yaml` - Promtail DaemonSet for log shipping
- `grafana-datasource.yaml` - Grafana datasource configuration for Loki
- `sample-app-deployment.yaml` - Sample application with logging

### Application Code
- `sample-app-bad-logging.py` - Example of poor logging practices
- `sample-app-good-logging.py` - Example of good structured logging

### Documentation
- `log-queries.md` - Comprehensive LogQL query examples

### Scripts
- `deploy.sh` - Automated deployment script
- `test.sh` - Automated test suite

## Quick Start

### Option 1: Automated Deployment

```bash
# Deploy entire logging stack
./deploy.sh

# This will:
# - Create logging namespace
# - Deploy Loki
# - Deploy Promtail
# - Optionally deploy sample application
```

### Option 2: Manual Deployment

```bash
# Create namespace
kubectl create namespace logging

# Deploy Loki
kubectl apply -f loki-config.yaml

# Wait for Loki to be ready
kubectl wait --for=condition=ready pod -l app=loki -n logging --timeout=300s

# Deploy Promtail
kubectl apply -f promtail-daemonset.yaml

# Verify deployment
kubectl get pods -n logging
```

### Step 2: Access Logs

#### Option A: Via Grafana (Recommended)

```bash
# If you have Grafana deployed, add Loki datasource
kubectl apply -f grafana-datasource.yaml

# Port forward to Grafana
kubectl port-forward -n logging svc/grafana 3000:3000

# Visit http://localhost:3000
# Go to Explore → Select Loki datasource → Write queries
```

#### Option B: Direct Loki API

```bash
# Port forward to Loki
kubectl port-forward -n logging svc/loki 3100:3100

# Query logs
curl -G -s "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={namespace="production"}' | jq .

# Stream logs in real-time
curl -G -s "http://localhost:3100/loki/api/v1/tail" \
  --data-urlencode 'query={namespace="production"}' \
  --data-urlencode 'limit=10'
```

## Using the Sample Application

### Deploy the Sample App

```bash
# Create ConfigMap with code
kubectl create configmap sample-app-code \
  --from-file=sample-app-good-logging.py

# Deploy app
kubectl apply -f sample-app-deployment.yaml

# Wait for it to be ready
kubectl wait --for=condition=ready pod -l app=sample-app --timeout=120s
```

### Generate Test Logs

```bash
# Port forward to the app
kubectl port-forward svc/sample-app 8080:80

# Generate logs
curl http://localhost:8080/api/users/123
curl http://localhost:8080/api/users/456
curl http://localhost:8080/api/slow
curl -X POST http://localhost:8080/api/orders \
  -H "Content-Type: application/json" \
  -d '{"items": ["item1"], "total": 99.99}'
```

### View the Logs

```bash
# Direct from pod (temporary)
kubectl logs -l app=sample-app --tail=20

# From Loki (persistent)
curl -G -s "http://localhost:3100/loki/api/v1/query" \
  --data-urlencode 'query={app="sample-app"}' | jq .
```

## Log Query Examples

### Basic Queries

```logql
# All logs from an app
{app="sample-app"}

# All errors
{namespace="production"} |= "ERROR"

# Parse JSON and filter
{app="sample-app"} | json | level="ERROR"
```

### Tracing Requests

```logql
# Follow a specific request
{namespace="production"} | json | request_id="abc-123"

# Find slow requests
{app="sample-app"} | json | duration_ms > 1000
```

### Aggregations

```logql
# Error rate
sum(rate({namespace="production"} |= "ERROR"[5m])) by (app)

# Request count
count_over_time({app="sample-app"}[1h])

# Average response time
avg_over_time({app="sample-app"} | json | unwrap duration_ms [5m])
```

See [log-queries.md](log-queries.md) for comprehensive examples.

## Understanding the Architecture

```
┌─────────────────────────────────────────┐
│          Kubernetes Cluster             │
│                                         │
│  ┌─────┐  ┌─────┐  ┌─────┐            │
│  │ Pod │  │ Pod │  │ Pod │            │
│  │ logs│  │ logs│  │ logs│            │
│  └──┬──┘  └──┬──┘  └──┬──┘            │
│     │        │        │                │
│     └────────┴────────┘                │
│              │                         │
│       ┌──────▼─────┐                  │
│       │  Promtail  │ (DaemonSet)      │
│       └──────┬─────┘                  │
│              │                         │
└──────────────┼─────────────────────────┘
               │
          ┌────▼────┐
          │  Loki   │ (Storage)
          └────┬────┘
               │
          ┌────▼────┐
          │ Grafana │ (UI)
          └─────────┘
```

**Components:**
1. **Application Pods** - Generate logs to stdout/stderr
2. **Promtail** - Runs on each node, collects and ships logs
3. **Loki** - Stores and indexes logs
4. **Grafana** - Query and visualize logs

## Learning Objectives

After completing this chapter, you should understand:

- ✅ Why `kubectl logs` is not sufficient for production
- ✅ How to implement structured logging in applications
- ✅ How centralized logging works (Loki + Promtail)
- ✅ How to query logs effectively with LogQL
- ✅ How to use correlation IDs for request tracing
- ✅ How to manage log retention and costs
- ✅ Security considerations for logging

## Common Issues

### Loki Pod Not Starting

```bash
# Check events
kubectl describe pod -l app=loki -n logging

# Common issues:
# - Insufficient memory (needs at least 512Mi)
# - PVC not binding (check storage class)
# - Configuration errors (check ConfigMap)
```

### Promtail Not Collecting Logs

```bash
# Check Promtail logs
kubectl logs -n logging daemonset/promtail

# Verify it's running on all nodes
kubectl get pods -n logging -l app=promtail -o wide

# Common issues:
# - Node access permissions
# - Log path configuration
# - Loki connection issues
```

### No Logs Appearing in Loki

```bash
# Check if logs are being generated
kubectl logs -l app=sample-app

# Check Promtail is shipping logs
kubectl logs -n logging -l app=promtail | grep -i "sent"

# Check Loki ingestion
kubectl logs -n logging -l app=loki | grep -i "ingester"

# Verify time sync (logs with future timestamps are rejected)
date
```

### Queries Returning No Results

```bash
# Check label names
curl -s http://localhost:3100/loki/api/v1/labels | jq .

# Check label values
curl -s http://localhost:3100/loki/api/v1/label/<label_name>/values | jq .

# Ensure time range includes recent data
# Loki rejects logs older than 7 days by default
```

## Comparing Bad vs Good Logging

### Bad Logging Example

```python
# From sample-app-bad-logging.py
print(f"Got user {user_id}")  # Unstructured, no context
print(f"Error: {e}")          # Generic, no details
```

**Problems:**
- Not structured (hard to parse)
- No correlation ID
- No severity level
- No context (timestamp, service, request)
- Logs sensitive data

### Good Logging Example

```python
# From sample-app-good-logging.py
log_json('INFO', 'User fetched successfully',
         user_id=user_id,
         request_id=request_id,
         duration_ms=123)
```

**Benefits:**
- Structured JSON
- Correlation ID included
- Proper severity level
- Rich context
- Sanitized sensitive data

## Cost Considerations

### Storage Costs

Loki storage grows based on:
- Log volume (MB/day)
- Retention period (days)
- Compression ratio (~10:1 typically)

**Example:**
- 1 GB/day × 30 days = 30 GB raw
- With compression: ~3 GB stored
- At $0.10/GB/month = $0.30/month

### Optimization Tips

1. **Log selectively**
   ```python
   # Sample successful requests (1%)
   if status == 200 and random() < 0.01:
       log_request()
   ```

2. **Use appropriate retention**
   ```yaml
   # Hot: 7 days (errors, warnings)
   # Warm: 30 days (info)
   # Cold: 90 days (audit)
   ```

3. **Filter before shipping**
   ```yaml
   # In Promtail config
   - drop:
       source: container
       expression: ".*health check.*"
   ```

## Security Best Practices

### Don't Log Sensitive Data

```python
# ❌ BAD
logger.info(f"User login: {username} / {password}")

# ✅ GOOD
logger.info("User login", extra={'user_id': user.id})
```

### Sanitize Logs

```python
def sanitize(data):
    sensitive = ['password', 'credit_card', 'ssn']
    return {k: '***' if k in sensitive else v 
            for k, v in data.items()}
```

### Access Control

```bash
# Restrict who can access logs
kubectl create rolebinding logs-reader \
  --clusterrole=view \
  --user=developer \
  --namespace=logging
```

## Testing the Examples

```bash
# Run automated tests
./test.sh

# Tests include:
# - Loki deployment
# - Promtail DaemonSet
# - Log collection
# - API functionality
# - Structured logging verification
```

## Cleanup

```bash
# Delete logging stack
kubectl delete namespace logging

# Delete sample app
kubectl delete -f sample-app-deployment.yaml
kubectl delete configmap sample-app-code
```

## Next Steps

- Read Chapter 3: "It Works on My Machine" (environment parity)
- Integrate logging into your applications
- Set up log-based alerts
- Create useful Grafana dashboards
- Implement log retention policies
- Practice writing LogQL queries

## Additional Resources

- [Loki Documentation](https://grafana.com/docs/loki/latest/)
- [LogQL Documentation](https://grafana.com/docs/loki/latest/logql/)
- [Promtail Configuration](https://grafana.com/docs/loki/latest/clients/promtail/configuration/)
- [Structured Logging Best Practices](https://www.structlog.org/)

## Troubleshooting Guide

See [log-queries.md](log-queries.md) for debugging queries and patterns.

---

**Remember: Good logging is the foundation of observability!** 🔍

Without proper logging, you're debugging blind. With centralized, structured logging, you can:
- Debug issues quickly
- Trace requests across services
- Create metrics from logs
- Alert on patterns
- Meet compliance requirements
