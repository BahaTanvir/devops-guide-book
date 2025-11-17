# Grafana/Prometheus Queries for Resource Monitoring
## Chapter 4: The Resource Crunch

## Memory Queries

### Memory usage vs limit
```promql
container_memory_working_set_bytes{namespace="production"} 
/ 
container_spec_memory_limit_bytes{namespace="production"} 
* 100
```

### Memory usage by pod
```promql
sum(container_memory_working_set_bytes{namespace="production"}) by (pod)
```

### Memory usage percentile
```promql
quantile_over_time(0.95, 
  container_memory_working_set_bytes{namespace="production"}[24h]
)
```

### OOMKill rate
```promql
rate(kube_pod_container_status_terminated_reason{reason="OOMKilled"}[5m])
```

## CPU Queries

### CPU usage vs limit
```promql
rate(container_cpu_usage_seconds_total{namespace="production"}[5m]) 
/ 
container_spec_cpu_quota{namespace="production"} 
* 100000
```

### CPU throttling rate
```promql
rate(container_cpu_cfs_throttled_seconds_total{namespace="production"}[5m])
```

### CPU usage by pod
```promql
sum(rate(container_cpu_usage_seconds_total{namespace="production"}[5m])) by (pod)
```

## Resource Waste

### Requested but unused memory
```promql
(
  sum(kube_pod_container_resource_requests{resource="memory", namespace="production"}) 
  - 
  sum(container_memory_working_set_bytes{namespace="production"})
) / 1024 / 1024 / 1024
```

### Requested but unused CPU
```promql
sum(kube_pod_container_resource_requests{resource="cpu", namespace="production"}) 
- 
sum(rate(container_cpu_usage_seconds_total{namespace="production"}[5m]))
```

## HPA Metrics

### Current vs desired replicas
```promql
kube_horizontalpodautoscaler_status_current_replicas
kube_horizontalpodautoscaler_status_desired_replicas
```

### HPA scaling events
```promql
changes(kube_horizontalpodautoscaler_status_current_replicas[1h])
```

## Node Resources

### Node memory available
```promql
node_memory_MemAvailable_bytes / node_memory_MemTotal_bytes * 100
```

### Node CPU usage
```promql
100 - (avg by (instance) (rate(node_cpu_seconds_total{mode="idle"}[5m])) * 100)
```

### Pods per node
```promql
sum(kube_pod_info) by (node)
```

## QoS Classes

### Pods by QoS class
```promql
count(kube_pod_status_qos_class) by (qos_class, namespace)
```

## Container Restarts

### Container restart rate
```promql
rate(kube_pod_container_status_restarts_total{namespace="production"}[5m])
```

### Total restarts by pod
```promql
sum(kube_pod_container_status_restarts_total{namespace="production"}) by (pod)
```
