# Chapter 2: The Mystery of the Disappearing Logs

> *"You can't debug what you can't see."*

---

## What You'll Learn

Sarah needs to debug an issue, but the logs have vanished. By the end of this chapter, you'll know how to:

- Explain why `kubectl logs` alone is insufficient for debugging production incidents
- Design a centralized logging pipeline suitable for Kubernetes-based microservices
- Implement structured, JSON-based logs with correlation IDs
- Write basic LogQL queries to search and aggregate logs in Loki/Grafana
- Balance log retention, cost, and compliance considerations
- Use logs as a signal source for alerts rather than just ad‑hoc debugging

---

## Sarah's Challenge

It was Monday morning, two weeks after the incident with the checkout service. Sarah had just settled into her desk with her coffee when a message popped up in the #platform-team channel:

```
@sarah Can you help debug an issue? 
Users reporting intermittent 500 errors on the API
Started about 30 minutes ago
```

Sarah felt more confident this time. She had learned from the last incident. First step: check the logs.

She opened her terminal and typed the command she'd used dozens of times:

```bash
kubectl logs deployment/api-service -n production
```

The output scrolled past—successful requests, database queries, normal operations. Everything looked fine. But users were reporting errors. She tried filtering for errors:

```bash
kubectl logs deployment/api-service -n production | grep -i error
```

A few errors appeared, but they were old—from hours ago, not the recent 30 minutes. Sarah frowned. Where were the recent error logs?

She tried checking individual pods:

```bash
kubectl get pods -n production -l app=api-service
```

Three pods were running. She checked the first one:

```bash
kubectl logs api-service-7d8f4c5b9d-abc123 -n production
```

The logs stopped 15 minutes ago. The pod was still running, but no new logs appeared. She checked the second pod—same thing. The third pod showed recent logs, but only from the last 5 minutes.

"Where are the logs from the past 30 minutes?" Sarah muttered to herself.

James walked by and noticed her confusion. "Lost logs?"

"Yeah," Sarah said, frustration creeping into her voice. "Users are reporting errors, but I can't find the logs. Some pods have logs that just... stop. And I can't see anything from when the errors actually started."

"Ah, the disappearing logs mystery," James said with a knowing smile. "Let me show you what's happening and how we fix this."

---

## Understanding the Problem

Sarah's situation revealed several fundamental issues with logging in Kubernetes and distributed systems:

### 1. Ephemeral Logs in Kubernetes

By default, `kubectl logs` only shows logs from the current container. Here's what Sarah didn't understand:

**Container Logs Are Ephemeral:**
- Logs are stored on the node's disk
- When a pod restarts, previous logs are gone
- When a node dies, all logs on that node are lost
- `kubectl logs` only shows stdout/stderr from the running container

**Pod Lifecycle and Logs:**
```
Pod Created → Logs Start → Pod Deleted → Logs Lost
                        ↓
                   Container Restart → Previous Logs Gone
```

Sarah's pods had likely restarted due to the errors, and she lost the critical logs from the incident.

### 2. The kubectl Logs Limitations

The `kubectl logs` command has several limitations:

**Time Window:**
```bash
kubectl logs pod-name              # Only current container
kubectl logs pod-name --previous   # Previous container (if it crashed)
kubectl logs pod-name --since=1h   # Last hour only
kubectl logs pod-name --tail=100   # Last 100 lines
```

**Multi-Pod Confusion:**
When you have multiple pods:
- `kubectl logs deployment/name` shows logs from a random pod
- No aggregation across pods
- No way to correlate logs from different pods
- Can't see logs from deleted pods

**Storage Limits:**
- Logs are rotated on the node
- Default: 10MB per container
- Older logs get deleted automatically
- No long-term retention

### 3. The Missing Context Problem

Even when Sarah found logs, they lacked context:

```
2024-01-22 10:15:23 ERROR: Database connection failed
```

Questions this log doesn't answer:
- Which user experienced this error?
- What request triggered it?
- Which pod/container logged this?
- How many times did this happen?
- What was the request ID?
- What else was happening at the same time?

### 4. Distributed System Challenges

TechFlow's microservices architecture made debugging harder:

```
User Request → API Gateway → Auth Service → API Service → Database
                                                      ↓
                                                  Cache Service
```

A single user request touches multiple services. Without correlation:
- Can't trace a request across services
- Can't see the full picture
- Can't identify which service actually failed
- Blame game begins ("It's not my service!")

### 5. The Three States of Logs

James explained that logs exist in three states:

**State 1: In Memory (Application)**
- Application generates logs
- Buffered in memory
- **Problem:** Lost if application crashes before flush

**State 2: On Disk (Node)**
- Written to node filesystem
- Available via `kubectl logs`
- **Problem:** Lost when pod/node dies

**State 3: Centralized (Log Aggregation)**
- Shipped to external system
- Persistent and searchable
- **Problem:** TechFlow didn't have this!

Sarah was only looking at State 2 logs, which were ephemeral and incomplete.

---

## The Senior's Perspective

James walked Sarah through his approach to logging in production systems.

### The Logging Mental Model

"When I debug production issues," James explained, "I think about logging in layers:

**Layer 1: Structured Logging**
- Logs should be machine-readable
- Include context: request ID, user ID, service name
- Use consistent format across all services

**Layer 2: Centralized Collection**
- All logs go to one place
- Survive pod/node failures
- Searchable and indexed

**Layer 3: Correlation**
- Connect logs across services
- Track request flow end-to-end
- Identify patterns and anomalies

**Layer 4: Retention and Cost**
- Keep what's useful
- Archive what's required
- Delete what's expensive

Without Layer 2, you're debugging blind."

### Questions Senior Engineers Ask About Logs

James shared his logging checklist:

1. **"Where are the logs?"**
   - Application stdout/stderr (good start)
   - But also: error logs, access logs, audit logs
   - Centralized system? (should be yes)

2. **"How long are logs kept?"**
   - Real-time logs: hours
   - Historical logs: days/weeks/months
   - Compliance logs: years
   - Cost vs. value trade-off

3. **"Can I correlate logs?"**
   - Request ID in every log?
   - Trace ID across services?
   - Timestamp synchronization?

4. **"What am I logging?"**
   - Too much: expensive, noisy
   - Too little: can't debug
   - Just right: actionable information

5. **"Who needs access?"**
   - Developers for debugging
   - SRE for incidents
   - Security for audits
   - Compliance for regulations

### The Logging Stack Decision Framework

James explained TechFlow's options:

**Option 1: ELK Stack (Elasticsearch, Logstash, Kibana)**
- **Pros:** Powerful search, flexible, self-hosted
- **Cons:** Operationally complex, resource-heavy, expensive at scale
- **Best for:** Teams with ops resources, on-prem requirements

**Option 2: EFK Stack (Elasticsearch, Fluentd, Kibana)**
- **Pros:** Similar to ELK, Fluentd is lighter and more flexible
- **Cons:** Still complex to operate
- **Best for:** Kubernetes-native environments

**Option 3: Loki + Grafana**
- **Pros:** Cost-effective, integrates with metrics, simpler than ELK
- **Cons:** Less powerful search than Elasticsearch
- **Best for:** Most Kubernetes environments, budget-conscious teams

**Option 4: Cloud Providers (CloudWatch, Cloud Logging, etc.)**
- **Pros:** Managed, integrated, easy to set up
- **Cons:** Vendor lock-in, can get expensive, limited features
- **Best for:** Teams already on that cloud, wanting simplicity

**Option 5: Third-Party SaaS (Datadog, Splunk, etc.)**
- **Pros:** Feature-rich, no ops burden, great UI
- **Cons:** Expensive at scale, data leaves your network
- **Best for:** Teams prioritizing features over cost

"For TechFlow," James said, "we'll use Loki + Grafana. It's cost-effective, Kubernetes-native, and you already know Grafana from our metrics dashboards."

---

## The Solution

James and Sarah set up a centralized logging system for TechFlow.

### Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                        Kubernetes Cluster                    │
│                                                              │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐                 │
│  │   Pod    │  │   Pod    │  │   Pod    │                 │
│  │ (stdout) │  │ (stdout) │  │ (stdout) │                 │
│  └────┬─────┘  └────┬─────┘  └────┬─────┘                 │
│       │             │             │                         │
│       └─────────────┴─────────────┘                         │
│                     │                                        │
│              ┌──────▼──────┐                                │
│              │   Promtail  │  (DaemonSet on each node)     │
│              │(Log Shipper)│                                │
│              └──────┬──────┘                                │
│                     │                                        │
└─────────────────────┼────────────────────────────────────────┘
                      │
                      ▼
              ┌───────────────┐
              │      Loki      │  (Log aggregation)
              │  (Storage)     │
              └───────┬────────┘
                      │
                      ▼
              ┌───────────────┐
              │    Grafana    │  (Visualization & Search)
              │  (Dashboard)   │
              └────────────────┘
```

### Step 1: Improve Application Logging

First, James showed Sarah how to improve the application logs themselves.

**Before (Bad Logging):**
```python
# api-service/app.py
@app.route('/api/users/<user_id>')
def get_user(user_id):
    try:
        user = db.get_user(user_id)
        return jsonify(user)
    except Exception as e:
        print(f"Error: {e}")
        return {"error": "Internal server error"}, 500
```

**Problems:**
- Generic error message
- No context
- No request ID
- No severity level
- Not structured

**After (Good Logging):**
```python
# api-service/app.py
import logging
import json
from flask import g, request
import uuid

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format='%(message)s'
)
logger = logging.getLogger(__name__)

def log_json(level, message, **kwargs):
    """Helper to log structured JSON"""
    log_entry = {
        'timestamp': datetime.utcnow().isoformat(),
        'level': level,
        'message': message,
        'service': 'api-service',
        'request_id': g.get('request_id', 'unknown'),
        **kwargs
    }
    logger.log(getattr(logging, level), json.dumps(log_entry))

@app.before_request
def before_request():
    """Generate request ID for correlation"""
    g.request_id = request.headers.get('X-Request-ID', str(uuid.uuid4()))
    log_json('INFO', 'Request started', 
             method=request.method,
             path=request.path,
             user_agent=request.headers.get('User-Agent'))

@app.route('/api/users/<user_id>')
def get_user(user_id):
    try:
        log_json('INFO', 'Fetching user', user_id=user_id)
        user = db.get_user(user_id)
        log_json('INFO', 'User fetched successfully', user_id=user_id)
        return jsonify(user)
    except DatabaseConnectionError as e:
        log_json('ERROR', 'Database connection failed',
                user_id=user_id,
                error=str(e),
                error_type='DatabaseConnectionError')
        return {"error": "Service temporarily unavailable"}, 503
    except UserNotFoundError:
        log_json('WARN', 'User not found', user_id=user_id)
        return {"error": "User not found"}, 404
    except Exception as e:
        log_json('ERROR', 'Unexpected error',
                user_id=user_id,
                error=str(e),
                error_type=type(e).__name__,
                traceback=traceback.format_exc())
        return {"error": "Internal server error"}, 500

@app.after_request
def after_request(response):
    """Log response"""
    log_json('INFO', 'Request completed',
             status_code=response.status_code,
             response_time_ms=(time.time() - g.get('start_time', time.time())) * 1000)
    return response
```

**Benefits:**
- Structured JSON logs
- Request ID for correlation
- Different severity levels
- Rich context
- Traceable across services

### Step 2: Deploy Loki (Deep Dive)

James created the Loki deployment configuration. This section shows a complete example that you can use as a **reference**. For production, always consult the official Loki documentation for your version, storage backend, and retention requirements.

**loki-config.yaml:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: loki-config
  namespace: logging
data:
  loki.yaml: |
    auth_enabled: false

    server:
      http_listen_port: 3100

    ingester:
      lifecycler:
        ring:
          kvstore:
            store: inmemory
          replication_factor: 1
      chunk_idle_period: 5m
      chunk_retain_period: 30s

    schema_config:
      configs:
        - from: 2024-01-01
          store: boltdb-shipper
          object_store: filesystem
          schema: v11
          index:
            prefix: index_
            period: 24h

    storage_config:
      boltdb_shipper:
        active_index_directory: /loki/boltdb-shipper-active
        cache_location: /loki/boltdb-shipper-cache
        shared_store: filesystem
      filesystem:
        directory: /loki/chunks

    limits_config:
      enforce_metric_name: false
      reject_old_samples: true
      reject_old_samples_max_age: 168h  # 7 days
      ingestion_rate_mb: 10
      ingestion_burst_size_mb: 20

    chunk_store_config:
      max_look_back_period: 720h  # 30 days

    table_manager:
      retention_deletes_enabled: true
      retention_period: 720h  # 30 days
---
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: loki
  namespace: logging
spec:
  serviceName: loki
  replicas: 1
  selector:
    matchLabels:
      app: loki
  template:
    metadata:
      labels:
        app: loki
    spec:
      containers:
      - name: loki
        image: grafana/loki:2.9.0
        ports:
        - containerPort: 3100
          name: http
        volumeMounts:
        - name: config
          mountPath: /etc/loki
        - name: storage
          mountPath: /loki
        resources:
          requests:
            memory: "512Mi"
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
      volumes:
      - name: config
        configMap:
          name: loki-config
  volumeClaimTemplates:
  - metadata:
      name: storage
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 10Gi
---
apiVersion: v1
kind: Service
metadata:
  name: loki
  namespace: logging
spec:
  type: ClusterIP
  ports:
  - port: 3100
    targetPort: 3100
    name: http
  selector:
    app: loki
```

### Step 3: Deploy Promtail (Log Shipper)

Promtail runs on every node and ships logs to Loki:

**promtail-daemonset.yaml:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: promtail-config
  namespace: logging
data:
  promtail.yaml: |
    server:
      http_listen_port: 9080
      grpc_listen_port: 0

    positions:
      filename: /tmp/positions.yaml

    clients:
      - url: http://loki:3100/loki/api/v1/push

    scrape_configs:
      # Scrape all pod logs
      - job_name: kubernetes-pods
        kubernetes_sd_configs:
          - role: pod
        relabel_configs:
          # Add namespace label
          - source_labels: [__meta_kubernetes_pod_namespace]
            target_label: namespace
          # Add pod name label
          - source_labels: [__meta_kubernetes_pod_name]
            target_label: pod
          # Add container name label
          - source_labels: [__meta_kubernetes_pod_container_name]
            target_label: container
          # Add app label
          - source_labels: [__meta_kubernetes_pod_label_app]
            target_label: app
          # Drop logs from logging namespace (avoid recursion)
          - source_labels: [__meta_kubernetes_pod_namespace]
            regex: logging
            action: drop
---
apiVersion: apps/v1
kind: DaemonSet
metadata:
  name: promtail
  namespace: logging
spec:
  selector:
    matchLabels:
      app: promtail
  template:
    metadata:
      labels:
        app: promtail
    spec:
      serviceAccountName: promtail
      containers:
      - name: promtail
        image: grafana/promtail:2.9.0
        args:
          - -config.file=/etc/promtail/promtail.yaml
        volumeMounts:
        - name: config
          mountPath: /etc/promtail
        - name: varlog
          mountPath: /var/log
          readOnly: true
        - name: varlibdockercontainers
          mountPath: /var/lib/docker/containers
          readOnly: true
        resources:
          requests:
            memory: "128Mi"
            cpu: "100m"
          limits:
            memory: "256Mi"
            cpu: "200m"
      volumes:
      - name: config
        configMap:
          name: promtail-config
      - name: varlog
        hostPath:
          path: /var/log
      - name: varlibdockercontainers
        hostPath:
          path: /var/lib/docker/containers
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: promtail
  namespace: logging
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: promtail
rules:
  - apiGroups: [""]
    resources:
      - nodes
      - nodes/proxy
      - services
      - endpoints
      - pods
    verbs: ["get", "watch", "list"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: promtail
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: promtail
subjects:
  - kind: ServiceAccount
    name: promtail
    namespace: logging
```

### Step 4: Configure Grafana

Add Loki as a data source in Grafana:

**grafana-datasource.yaml:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: grafana-datasources
  namespace: logging
data:
  datasources.yaml: |
    apiVersion: 1
    datasources:
      - name: Loki
        type: loki
        access: proxy
        url: http://loki:3100
        isDefault: true
        editable: true
```

### Step 5: Deploy Everything

```bash
# Create logging namespace
kubectl create namespace logging

# Deploy Loki
kubectl apply -f loki-config.yaml

# Deploy Promtail
kubectl apply -f promtail-daemonset.yaml

# Wait for Loki to be ready
kubectl wait --for=condition=ready pod -l app=loki -n logging --timeout=300s

# Verify Promtail is running on all nodes
kubectl get pods -n logging -l app=promtail -o wide
```

### Step 6: Searching Logs in Grafana

Now Sarah could search logs effectively:

**Query Examples:**

1. **Find all errors in the last hour:**
```logql
{namespace="production"} |= "ERROR" | json
```

2. **Track a specific request:**
```logql
{namespace="production"} | json | request_id="abc-123-def"
```

3. **Find database connection errors:**
```logql
{app="api-service"} |= "DatabaseConnectionError" | json
```

4. **See error rate over time:**
```logql
sum(rate({namespace="production"} |= "ERROR"[5m])) by (app)
```

5. **Find slow requests (> 1 second):**
```logql
{namespace="production"} | json | response_time_ms > 1000
```

### Step 7: Log Retention and Cost Management

James explained the cost considerations:

**Retention Policy:**
```yaml
# In loki-config.yaml
table_manager:
  retention_deletes_enabled: true
  retention_period: 720h  # 30 days for production
```

**Different retention for different namespaces:**
```logql
# Hot logs (7 days, fast access): Production errors and warnings
# Warm logs (30 days, slower access): Production info logs
# Cold logs (90 days, archive): Audit logs
# Deleted (>90 days): Debug logs
```

**Cost Optimization Tips:**
1. **Don't log everything** - Be selective
2. **Use appropriate log levels** - Debug only in dev
3. **Sample high-volume logs** - Log 1% of successful requests
4. **Compress old logs** - Move to cheaper storage
5. **Delete what you don't need** - Debug logs after 7 days

---

## Lessons Learned

Sarah documented the key lessons from setting up centralized logging:

### 1. Ephemeral Logs Are Not Enough

**The Lesson:**
`kubectl logs` is useful for quick checks, but not for debugging production issues.

**How to Apply:**
- Always use centralized logging in production
- Keep logs beyond pod lifecycle
- Make logs searchable and correlatable

**Red Flags:**
- No centralized logging system
- Relying on `kubectl logs` for debugging
- Logs disappear when pods restart

### 2. Structure Your Logs

**The Lesson:**
Unstructured logs are hard to search and analyze. JSON-structured logs enable powerful queries.

**Good Structured Log:**
```json
{
  "timestamp": "2024-01-22T10:15:23Z",
  "level": "ERROR",
  "message": "Database connection failed",
  "service": "api-service",
  "request_id": "req-123-abc",
  "user_id": "user-456",
  "error_type": "DatabaseConnectionError",
  "retry_attempt": 2
}
```

**Benefits:**
- Easy to parse programmatically
- Can filter by any field
- Aggregate and analyze
- Create metrics from logs

### 3. Correlation Is Key

**The Lesson:**
In microservices, a single request touches multiple services. Correlation IDs tie logs together.

**Implementation:**
```python
# Generate request ID at entry point (API Gateway)
request_id = str(uuid.uuid4())

# Pass in headers to downstream services
headers = {'X-Request-ID': request_id}

# Log with request ID in every service
logger.info("Processing request", extra={'request_id': request_id})
```

**Benefits:**
- Trace full request flow
- Identify bottlenecks
- Debug distributed issues
- Create dependency maps

### 4. Log Levels Matter

**The Lesson:**
Use appropriate log levels to control noise and cost.

**Log Level Guidelines:**
- **DEBUG:** Detailed information for diagnosing problems (dev only)
- **INFO:** General informational messages (key operations)
- **WARN:** Warning messages (potential issues)
- **ERROR:** Error messages (failures that don't crash the app)
- **FATAL:** Critical failures (application crash)

**In Production:**
```python
# Production: INFO and above
logging.basicConfig(level=logging.INFO)

# Development: DEBUG and above
logging.basicConfig(level=logging.DEBUG)
```

### 5. Balance Cost and Value

**The Lesson:**
Logs are expensive. Log what's useful, not everything.

**Cost Factors:**
- **Storage:** Volume of logs × retention period
- **Ingestion:** Cost per GB ingested
- **Search:** Query costs
- **Network:** Data transfer costs

**Optimization Strategies:**
```python
# Sample successful requests (log 1%)
if response.status_code == 200:
    if random.random() < 0.01:  # 1% sampling
        log_request(request, response)
else:
    # Always log errors
    log_request(request, response)
```

### 6. Retention Policies Are Essential

**The Lesson:**
Different logs have different value over time. Implement tiered retention.

**Retention Strategy:**
```
Hot Tier (1-7 days):     All logs, fast search
Warm Tier (8-30 days):   Errors and warnings only
Cold Tier (31-90 days):  Audit logs, compressed
Archive (91-365 days):   Compliance requirements only
Deleted (>365 days):     Unless legally required
```

### 7. Security and Compliance

**The Lesson:**
Logs contain sensitive data. Handle them carefully.

**Best Practices:**
```python
# DON'T log sensitive data
logger.info(f"User logged in: {username} with password {password}")  # BAD!

# DO sanitize logs
logger.info(f"User logged in", extra={
    'user_id': user.id,
    'ip_address': request.ip,
    # Password never logged
})

# Redact sensitive fields
def sanitize_log(data):
    sensitive_fields = ['password', 'ssn', 'credit_card']
    return {k: '***REDACTED***' if k in sensitive_fields else v 
            for k, v in data.items()}
```

**Compliance Considerations:**
- GDPR: Personal data retention and deletion
- HIPAA: Healthcare data security
- PCI DSS: Credit card data protection
- SOX: Financial record retention

### 8. Alerting on Logs

**The Lesson:**
Logs aren't just for debugging—they can trigger alerts.

**Alert Examples:**
```logql
# Alert on high error rate
sum(rate({namespace="production"} |= "ERROR"[5m])) by (app) > 10

# Alert on specific errors
count_over_time({app="api-service"} |= "DatabaseConnectionError"[5m]) > 5

# Alert on no logs (service might be down)
sum(count_over_time({app="api-service"}[5m])) == 0
```

---

## Reflection Questions

Consider how logging applies to your environment:

1. **Your Current Logging:**
   - How do you access logs in your production environment?
   - Do logs survive pod/container restarts?
   - How long are logs retained?

2. **Log Structure:**
   - Are your logs structured (JSON) or unstructured (plain text)?
   - Do you use consistent log levels across services?
   - Can you easily search and filter logs?

3. **Correlation:**
   - Do you use request IDs or trace IDs?
   - Can you follow a request across multiple services?
   - How do you debug distributed system issues?

4. **Cost and Retention:**
   - What's your monthly logging cost?
   - Do you have a retention policy?
   - Are you logging too much or too little?

5. **Security:**
   - Do you log sensitive data?
   - Who has access to production logs?
   - Do logs meet compliance requirements?

6. **Observability:**
   - Do you create alerts from logs?
   - Can you create metrics from log patterns?
   - How quickly can you find root cause of issues?

---

## What's Next?

Sarah now had centralized logging in place. She could:
- Search logs across all pods and services
- Correlate requests with trace IDs
- Debug issues even after pods restart
- Create alerts based on log patterns

But she quickly discovered another challenge: the logs looked perfect in her local environment and staging, but production behaved differently. Environment-specific configurations were causing issues again.

In Chapter 3, "It Works on My Machine," Sarah will learn about environment parity and configuration management—ensuring that what works locally actually works in production.

---

## Code Examples

All the code examples from this chapter are available in the GitHub repository:

```bash
# Clone the repository
git clone https://github.com/BahaTanvir/devops-guide-book.git
cd devops-guide-book/examples/chapter-02

# Or if you already have the repo
cd examples/chapter-02
```

See the [Chapter 2 Examples README](https://github.com/BahaTanvir/devops-guide-book/tree/main/examples/chapter-02) for detailed instructions on:
- Deploying Loki and Promtail
- Configuring structured logging in your applications
- Creating useful log queries
- Setting up log-based alerts

**Try it yourself:**
1. Deploy the logging stack in your cluster
2. Update your application to use structured logging
3. Practice writing LogQL queries
4. Set up alerts based on log patterns
5. Experiment with retention policies

Remember: Good logging is the foundation of observability! 🔍
