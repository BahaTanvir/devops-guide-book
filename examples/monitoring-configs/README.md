# Monitoring Configurations

This directory contains monitoring and observability configurations.

## Available Configurations

### Prometheus
- **prometheus.yml** - Prometheus server configuration
- **alert-rules/** - Alerting rule examples
- **recording-rules/** - Recording rule examples
- **service-discovery/** - Service discovery configurations

### Grafana
- **dashboards/** - Pre-built Grafana dashboards
- **datasources/** - Datasource configurations
- **alerting/** - Grafana alerting configurations

### Alertmanager
- **alertmanager.yml** - Alertmanager configuration
- **routes/** - Alert routing examples
- **receivers/** - Notification receiver examples

### Application Instrumentation
- **python/** - Python application instrumentation
- **nodejs/** - Node.js application instrumentation
- **go/** - Go application instrumentation
- **java/** - Java application instrumentation

### Jaeger/Tracing
- **jaeger-deployment.yaml** - Jaeger deployment
- **otel-collector/** - OpenTelemetry Collector configs

### Log Aggregation
- **fluentd/** - Fluentd configurations
- **filebeat/** - Filebeat configurations
- **promtail/** - Promtail (Loki) configurations

## Quick Start

### Deploy Prometheus Stack
```bash
kubectl apply -f monitoring-configs/prometheus-stack/
```

### Import Grafana Dashboard
```bash
# Via Grafana UI or API
curl -X POST http://grafana:3000/api/dashboards/db \
  -H "Content-Type: application/json" \
  -d @dashboards/kubernetes-cluster.json
```

## Metrics to Monitor

### The Four Golden Signals
1. **Latency** - Request duration
2. **Traffic** - Request rate
3. **Errors** - Error rate
4. **Saturation** - Resource utilization

### USE Method (Resources)
- **Utilization** - % time busy
- **Saturation** - Queue depth
- **Errors** - Error count

### RED Method (Services)
- **Rate** - Requests per second
- **Errors** - Failed requests
- **Duration** - Latency distribution

*Monitoring configs coming soon...*
