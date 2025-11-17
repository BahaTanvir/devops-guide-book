# Chapter 4: The Resource Crunch

> *"Resource limits are guardrails, not restrictions."*

---

## Sarah's Challenge

Two weeks after fixing the configuration issues, Sarah was feeling confident. The notification service was running smoothly in production, sending emails and push notifications without issues. Everything seemed perfect.

Until Tuesday at 2 PM.

Her phone buzzed with alerts:

```
🚨 CRITICAL: notification-service pods restarting
🚨 CRITICAL: notification-service - OOMKilled
🚨 WARNING: notification-service - CrashLoopBackOff
```

Sarah's stomach dropped. OOMKilled? She'd heard about this—it meant "Out Of Memory Killed." The pods were using too much memory and Kubernetes was killing them.

She quickly checked the pod status:

```bash
kubectl get pods -n production -l app=notification-service
```

```
NAME                                    READY   STATUS      RESTARTS   AGE
notification-service-7d8f4c5b9d-8xk2p   0/1     OOMKilled   5          10m
notification-service-7d8f4c5b9d-j7h9m   0/1     OOMKilled   4          10m
notification-service-7d8f4c5b9d-m2p4w   1/1     Running     3          10m
```

Two pods were repeatedly being killed, and even the running one had restarted 3 times. She checked the events:

```bash
kubectl get events -n production --sort-by='.lastTimestamp' | grep notification-service
```

```
10m    Warning   OOMKilling    pod/notification-service-7d8f4c5b9d-8xk2p   Memory cgroup out of memory
10m    Warning   BackOff       pod/notification-service-7d8f4c5b9d-8xk2p   Back-off restarting failed container
9m     Warning   OOMKilling    pod/notification-service-7d8f4c5b9d-j7h9m   Memory cgroup out of memory
```

The pods were being killed because they exceeded their memory limit. But Sarah had set memory limits based on what seemed reasonable. What went wrong?

She looked at the deployment configuration:

```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

These values had worked fine for weeks. Why were they suddenly insufficient?

James walked over, noticed her concerned expression. "OOMKilled issues?"

"Yeah," Sarah said. "The notification service keeps getting killed for using too much memory. But I set limits!"

"Setting limits is good," James said, "but the wrong limits can be worse than no limits. Let's figure out what's actually happening with your pods."

---

## Understanding the Problem

Sarah's resource management issues revealed several fundamental concepts about how Kubernetes manages resources and why pods get killed.

### 1. Requests vs Limits

Kubernetes has two resource specifications that many engineers confuse:

**Requests (Minimum Guarantee):**
- "I need at least this much to run"
- Used by the scheduler to decide which node to place the pod on
- Pod won't be scheduled if node doesn't have available resources
- Pod can use more than requested

**Limits (Maximum Allowed):**
- "Don't let me use more than this"
- Enforced by the container runtime
- If exceeded:
  - **CPU**: Throttled (slowed down)
  - **Memory**: Killed (OOMKilled)

```yaml
resources:
  requests:     # "I need..."
    memory: "256Mi"
    cpu: "250m"
  limits:       # "Don't let me exceed..."
    memory: "512Mi"
    cpu: "500m"
```

**Visual Representation:**
```
Memory Usage Timeline:
0Mi ────────────────────────────────────> Time
     ↑              ↑                ↑
     Pod starts    Request (256Mi)  Limit (512Mi)
                   Guaranteed       Kill if exceeded!
     
     ├──────┬──────────────┬───────────┤
     0-256Mi│ 256-512Mi     │ >512Mi    
     Safe   │ Can use       │ OOMKilled
            │ if available  │
```

### 2. The OOMKilled Problem

When a pod exceeds its memory limit, the kernel's OOM (Out Of Memory) killer immediately terminates it. There's no graceful degradation—it's instant death.

**What Happens:**
1. Application uses more memory than limit
2. Kernel detects memory limit exceeded
3. OOM killer terminates the process
4. Container exits with code 137 (128 + 9 SIGKILL)
5. Kubernetes sees container died
6. Kubelet restarts the container
7. If it happens repeatedly → CrashLoopBackOff

**Why It Happens:**
- Memory leak in application
- Sudden spike in traffic
- Large data processing
- Caching gone wrong
- Limits set too low

### 3. CPU Throttling

Unlike memory (which kills), CPU limits throttle:

**CPU Limit Exceeded:**
- Process doesn't get killed
- Gets throttled (slowed down)
- Can lead to:
  - Slow response times
  - Health check failures (timeouts)
  - Request queuing
  - Cascading failures

**Example:**
```
CPU Limit: 1 core (1000m)
App tries to use: 1.5 cores

Result: App runs at 66% speed (1.0/1.5)
        Everything takes 50% longer
        Requests start timing out
```

### 4. Resource Units in Kubernetes

**Memory Units:**
```
Ki = Kibibyte (1024 bytes)
Mi = Mebibyte (1024 Ki = 1,048,576 bytes)
Gi = Gibibyte (1024 Mi)

128974848 bytes = 123Mi
1Gi = 1024Mi = 1,048,576Ki
```

**CPU Units:**
```
1 CPU = 1000m (millicores)
500m = 0.5 CPU
100m = 0.1 CPU = 10% of one CPU core
1m = 0.001 CPU (minimum)

Example:
250m = 1/4 of a CPU core
2000m = 2 = 2 full CPU cores
```

### 5. Quality of Service (QoS) Classes

Kubernetes assigns QoS classes based on resource settings:

**Guaranteed (Highest Priority):**
- Requests = Limits for all containers
- Least likely to be evicted
- Example:
  ```yaml
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "512Mi"  # Same as request
      cpu: "500m"       # Same as request
  ```

**Burstable (Medium Priority):**
- Requests < Limits, or only requests set
- Can use extra resources if available
- Sarah's configuration (most common)
  ```yaml
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"  # Higher than request
      cpu: "500m"
  ```

**BestEffort (Lowest Priority):**
- No requests or limits set
- First to be evicted under pressure
- Not recommended for production

**Eviction Priority:**
```
BestEffort → Burstable → Guaranteed
(Killed first)        (Killed last)
```

### 6. Node Resource Pressure

When a node runs out of resources, Kubernetes evicts pods:

**Memory Pressure:**
- Node is running out of memory
- Kubernetes evicts BestEffort pods first
- Then Burstable pods exceeding requests
- Finally Guaranteed pods (only in extreme cases)

**Disk Pressure:**
- Node running out of disk space
- Pods evicted based on QoS class
- Ephemeral storage limits can trigger this

### 7. Why Sarah's Pods Were OOMKilled

After investigation, James and Sarah discovered several issues:

**Issue 1: Memory Leak**
The notification service had a memory leak—it cached notification templates in memory but never cleared old ones.

**Issue 2: Traffic Spike**
Marketing sent a campaign to all users simultaneously, creating 10x normal notification volume.

**Issue 3: Limits Too Low**
256Mi request was reasonable for normal load, but 512Mi limit was too low for peak traffic with the memory leak.

**Issue 4: No Horizontal Scaling**
Only 3 pods handled all traffic—no autoscaling configured.

---

## The Senior's Perspective

James explained his approach to resource management.

### The Resource Management Mental Model

"Think of Kubernetes resource management like a hotel," James explained:

**Requests = Room Reservation**
- You book a room (guarantee you'll have space)
- Hotel can't overbook beyond capacity
- You might not use the whole room, but it's yours

**Limits = Fire Code Capacity**
- Maximum occupancy for safety
- Exceeding it triggers immediate action
- Based on safety, not comfort

**No Resources Set = Standby Passenger**
- Hope for space but no guarantee
- First to lose seat if overbooked

### Questions Senior Engineers Ask About Resources

1. **"What does this application actually use?"**
   - Not guessing—measure it
   - Monitor in staging under load
   - Profile memory and CPU usage
   - Understand growth patterns

2. **"What happens under peak load?"**
   - Normal load vs. spike load
   - Daily/weekly patterns
   - Campaign/event driven spikes
   - Gradual growth over time

3. **"What's the cost of being wrong?"**
   - Too low → OOMKilled, poor performance
   - Too high → wasted money, limited scale
   - Balance reliability vs. cost

4. **"Should this horizontally or vertically scale?"**
   - **Horizontal**: More pods (better for stateless)
   - **Vertical**: Bigger pods (better for stateful)
   - Most web services: horizontal

5. **"What's the blast radius of resource issues?"**
   - One pod dying → service degraded
   - All pods dying → service down
   - Node resource exhaustion → multiple services impacted

### Rightsizing Strategy

James shared his approach:

**Phase 1: Measure**
```bash
# Monitor actual usage in staging
kubectl top pods -n staging

# Use metrics server
kubectl get --raw /apis/metrics.k8s.io/v1beta1/pods

# Use Prometheus queries
rate(container_cpu_usage_seconds_total[5m])
container_memory_working_set_bytes
```

**Phase 2: Set Conservative Limits**
```
Requests: P50 usage (typical)
Limits: P95 usage (peaks) + 20% buffer
```

**Phase 3: Monitor and Adjust**
```
Watch for:
- OOMKilled events
- CPU throttling
- Resource waste
- Performance issues
```

**Phase 4: Enable Autoscaling**
```yaml
# Scale based on actual usage
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
```

### Common Resource Patterns

**Pattern 1: CPU-Intensive (Data Processing)**
```yaml
resources:
  requests:
    memory: "512Mi"
    cpu: "1000m"      # High CPU
  limits:
    memory: "1Gi"
    cpu: "2000m"      # Allow bursting
```

**Pattern 2: Memory-Intensive (Caching)**
```yaml
resources:
  requests:
    memory: "2Gi"     # High memory
    cpu: "250m"
  limits:
    memory: "4Gi"     # Generous buffer
    cpu: "500m"
```

**Pattern 3: Balanced Web Service**
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

**Pattern 4: Guaranteed QoS (Critical)**
```yaml
resources:
  requests:
    memory: "1Gi"
    cpu: "1000m"
  limits:
    memory: "1Gi"     # Same as request
    cpu: "1000m"      # Same as request
```

---

## The Solution

James and Sarah implemented proper resource management.

### Step 1: Measure Actual Usage

First, they measured what the notification service actually used:

```bash
# Install metrics-server if not already present
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# Check current usage
kubectl top pods -n production -l app=notification-service
```

Output:
```
NAME                                    CPU(cores)   MEMORY(bytes)
notification-service-7d8f4c5b9d-8xk2p   245m         487Mi
notification-service-7d8f4c5b9d-j7h9m   198m         456Mi
notification-service-7d8f4c5b9d-m2p4w   267m         512Mi  ← At limit!
```

They saw pods consistently using 450-512Mi of memory—right at the limit!

### Step 2: Analyze Memory Usage Over Time

Using Prometheus, they queried historical memory usage:

```promql
# Memory usage over last 24 hours
container_memory_working_set_bytes{
  pod=~"notification-service-.*",
  namespace="production"
}

# Results:
# P50 (median): 380Mi
# P95 (95th percentile): 520Mi ← Exceeds current limit!
# P99: 580Mi
# Max: 620Mi
```

**Discovery:** The 512Mi limit was too low for peak usage!

### Step 3: Check for Memory Leaks

They added memory profiling to identify the leak:

```python
# notification_service.py
import tracemalloc
import logging

# Start memory profiling
tracemalloc.start()

# Periodic memory snapshot
@app.route('/debug/memory')
def memory_snapshot():
    snapshot = tracemalloc.take_snapshot()
    top_stats = snapshot.statistics('lineno')
    
    memory_info = []
    for stat in top_stats[:10]:
        memory_info.append({
            'file': stat.traceback.format()[0],
            'size_mb': stat.size / 1024 / 1024
        })
    
    return jsonify({
        'current_mb': tracemalloc.get_traced_memory()[0] / 1024 / 1024,
        'peak_mb': tracemalloc.get_traced_memory()[1] / 1024 / 1024,
        'top_allocations': memory_info
    })
```

**Discovery:** Template cache was growing indefinitely!

### Step 4: Fix the Memory Leak

```python
# Before (Memory Leak):
template_cache = {}  # Grows forever!

def load_template(template_name):
    if template_name not in template_cache:
        template_cache[template_name] = load_from_disk(template_name)
    return template_cache[template_name]

# After (Fixed with LRU Cache):
from functools import lru_cache

@lru_cache(maxsize=100)  # Cache only 100 templates
def load_template(template_name):
    return load_from_disk(template_name)

# Or use cachetools with TTL:
from cachetools import TTLCache

template_cache = TTLCache(maxsize=100, ttl=3600)  # 1 hour TTL
```

### Step 5: Set Appropriate Resource Limits

Based on measurements and the memory leak fix:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notification-service
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: notification-service
  template:
    metadata:
      labels:
        app: notification-service
    spec:
      containers:
      - name: notification
        image: techflow/notification-service:v1.3.0
        ports:
        - containerPort: 8080
        resources:
          requests:
            memory: "384Mi"  # P50 + buffer
            cpu: "250m"       # Typical usage
          limits:
            memory: "768Mi"  # P95 + 50% buffer
            cpu: "1000m"      # Allow bursting to 1 core
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 30
          periodSeconds: 10
          timeoutSeconds: 5      # Account for CPU throttling
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
```

**Key Changes:**
- Memory request: 256Mi → 384Mi (based on P50)
- Memory limit: 512Mi → 768Mi (based on P95 + buffer)
- CPU limit: 500m → 1000m (allow bursting)
- Increased timeouts (account for CPU throttling)

### Step 6: Configure Horizontal Pod Autoscaler (Deep Dive)

To handle traffic spikes, they added autoscaling. This example shows a fairly advanced HPA configuration; on a first read, focus on the idea that Kubernetes can scale based on resource usage. You can come back to the exact YAML when you're ready to implement it.

```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: notification-service-hpa
  namespace: production
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: notification-service
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70  # Scale when avg CPU > 70%
  - type: Resource
    resource:
      name: memory
      target:
        type: Utilization
        averageUtilization: 80  # Scale when avg memory > 80%
  behavior:
    scaleDown:
      stabilizationWindowSeconds: 300  # Wait 5 min before scaling down
      policies:
      - type: Percent
        value: 50  # Remove max 50% of pods at once
        periodSeconds: 60
    scaleUp:
      stabilizationWindowSeconds: 0    # Scale up immediately
      policies:
      - type: Percent
        value: 100  # Double pods if needed
        periodSeconds: 15
      - type: Pods
        value: 4    # Or add 4 pods
        periodSeconds: 15
      selectPolicy: Max  # Use whichever scales faster
```

**HPA Configuration Explained:**

**Scale Up (Aggressive):**
- No stabilization window (immediate)
- Can double pods (100%) or add 4 pods
- Uses whichever is faster
- Checks every 15 seconds

**Scale Down (Conservative):**
- 5-minute stabilization window
- Max 50% reduction at once
- Prevents flapping

**Triggers:**
- CPU > 70% average
- Memory > 80% average

### Step 7: Set Resource Quotas and Limit Ranges

To prevent runaway resource usage across the namespace:

```yaml
# Namespace ResourceQuota
apiVersion: v1
kind: ResourceQuota
metadata:
  name: production-quota
  namespace: production
spec:
  hard:
    requests.cpu: "50"        # Max 50 CPUs requested
    requests.memory: "100Gi"  # Max 100Gi memory requested
    limits.cpu: "100"         # Max 100 CPUs limit
    limits.memory: "200Gi"    # Max 200Gi memory limit
    pods: "100"               # Max 100 pods
---
# LimitRange (defaults and constraints)
apiVersion: v1
kind: LimitRange
metadata:
  name: production-limits
  namespace: production
spec:
  limits:
  - max:  # Maximum per pod
      memory: "4Gi"
      cpu: "4"
    min:  # Minimum per pod
      memory: "64Mi"
      cpu: "50m"
    default:  # Default limit if not specified
      memory: "512Mi"
      cpu: "500m"
    defaultRequest:  # Default request if not specified
      memory: "256Mi"
      cpu: "250m"
    type: Container
```

### Step 8: Monitor Resource Usage

Set up alerts for resource issues:

```yaml
# Prometheus AlertManager rules
groups:
- name: resources
  rules:
  - alert: PodOOMKilled
    expr: |
      increase(kube_pod_container_status_restarts_total[5m]) > 0
    for: 1m
    labels:
      severity: critical
    annotations:
      summary: "Pod {{ $labels.pod }} restarted in the last 5 minutes"
      description: "One or more containers restarted recently. Check if the cause was OOMKilled using logs or events."

  - alert: PodCPUThrottling
    expr: |
      rate(container_cpu_cfs_throttled_seconds_total[5m]) > 0.1
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Pod {{ $labels.pod }} is being CPU throttled (example threshold)"
      description: "CPU throttling may impact performance. Tune this threshold based on your workload and SLOs."

  - alert: HighMemoryUsage
    expr: |
      container_memory_working_set_bytes / container_spec_memory_limit_bytes > 0.9
    for: 5m
    labels:
      severity: warning
    annotations:
      summary: "Pod {{ $labels.pod }} using >90% of memory limit"
      description: "May be OOMKilled soon"

  - alert: PodCrashLooping
    expr: |
      rate(kube_pod_container_status_restarts_total[15m]) > 0
    for: 5m
    labels:
      severity: critical
    annotations:
      summary: "Pod {{ $labels.pod }} is crash looping"
      description: "Pod restarting frequently"
```

### Step 9: Create Resource Management Dashboard

They created a Grafana dashboard to visualize:

```
Panel 1: Memory Usage vs Limit
Panel 2: CPU Usage vs Limit  
Panel 3: Pod Restarts (OOMKilled)
Panel 4: HPA Scaling Events
Panel 5: Resource Waste (Requested but Unused)
Panel 6: Throttling Events
```

**Key Queries:**
```promql
# Memory usage percentage
container_memory_working_set_bytes / container_spec_memory_limit_bytes * 100

# CPU throttling
rate(container_cpu_cfs_throttled_seconds_total[5m])

# Resource waste
(container_spec_memory_limit_bytes - container_memory_working_set_bytes) / 1024 / 1024 / 1024
```

---

## Lessons Learned

### 1. Always Set Resource Limits

**The Lesson:**
Pods without limits can consume all node resources, impacting other pods.

**Why It Matters:**
- One pod can bring down entire node
- Noisy neighbor problem
- Makes capacity planning impossible

**Implementation:**
```yaml
# ❌ Bad (No limits)
containers:
- name: app
  image: myapp:latest
  # No resources defined!

# ✅ Good (With limits)
containers:
- name: app
  image: myapp:latest
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"
```

### 2. Requests Are for Scheduling, Limits Are for Safety

**The Lesson:**
- **Requests**: Tell scheduler where pod can fit
- **Limits**: Prevent runaway resource usage

**Common Mistake:**
```yaml
# ❌ Setting requests = limits unnecessarily
resources:
  requests:
    memory: "2Gi"
    cpu: "2000m"
  limits:
    memory: "2Gi"    # Same as request
    cpu: "2000m"     # Same as request
# This reserves resources that might not be used!
```

**Better:**
```yaml
# ✅ Allow bursting to limits
resources:
  requests:
    memory: "512Mi"   # What I typically need
    cpu: "500m"
  limits:
    memory: "1Gi"     # Can burst to this
    cpu: "1000m"
```

### 3. Measure, Don't Guess

**The Lesson:**
Don't guess resource requirements—measure them.

**How to Measure:**
```bash
# Current usage
kubectl top pods

# Historical data (Prometheus)
container_memory_working_set_bytes
rate(container_cpu_usage_seconds_total[5m])

# Load testing
# Run load tests and monitor resource usage
```

**Rightsizing Formula:**
```
Requests = P50 (median) usage + 10% buffer
Limits = P95 (95th percentile) usage + 20-50% buffer
```

### 4. Memory Kills, CPU Throttles

**The Lesson:**
Understand the difference:
- **Memory over limit**: Pod killed (OOMKilled)
- **CPU over limit**: Pod throttled (slowed down)

**Implications:**
- Memory limits must be generous (killing is severe)
- CPU limits can be tighter (throttling is recoverable)
- CPU throttling can cause timeout errors

**Example:**
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "100m"
  limits:
    memory: "512Mi"   # Generous (2x request)
    cpu: "1000m"      # Very generous (10x request - allow bursting)
```

### 5. Use Horizontal Pod Autoscaling

**The Lesson:**
Static pod counts can't handle variable load. Use HPA.

**Benefits:**
- Automatic scaling based on metrics
- Handle traffic spikes
- Save money during low traffic
- Prevent overload

**Configuration:**
```yaml
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: myapp-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: myapp
  minReplicas: 2
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

### 6. Quality of Service Matters

**The Lesson:**
QoS class determines eviction priority during resource pressure.

**Classes:**
```
Guaranteed (requests = limits)
  ↓ Less likely to be evicted
Burstable (requests < limits)
  ↓
BestEffort (no resources set)
  ↓ First to be evicted
```

**When to Use:**
- **Guaranteed**: Critical services (databases, core services)
- **Burstable**: Most applications (web services, APIs)
- **BestEffort**: Batch jobs, dev/test only

### 7. Monitor and Alert on Resource Issues

**The Lesson:**
Don't wait for OOMKilled—alert before it happens.

**Key Alerts:**
- Memory usage > 90% of limit
- CPU throttling occurring
- OOMKilled events
- Crash loop backoff
- HPA scaling events

**Grafana Queries:**
```promql
# Approaching memory limit
(container_memory_working_set_bytes / container_spec_memory_limit_bytes) > 0.9

# CPU throttling
rate(container_cpu_cfs_throttled_seconds_total[5m]) > 0.1

# OOMKilled
rate(kube_pod_container_status_terminated_reason{reason="OOMKilled"}[5m]) > 0
```

### 8. Resource Quotas Prevent Disasters

**The Lesson:**
Set namespace-level quotas to prevent one app from consuming all resources.

**Why:**
- Limit blast radius
- Enforce resource governance
- Prevent accidental overprovisioning
- Fair sharing of cluster resources

**Implementation:**
```yaml
apiVersion: v1
kind: ResourceQuota
metadata:
  name: prod-quota
  namespace: production
spec:
  hard:
    requests.cpu: "50"
    requests.memory: "100Gi"
    limits.cpu: "100"
    limits.memory: "200Gi"
```

---

## Reflection Questions

1. **Your Current Resource Settings:**
   - Do all your pods have resource requests and limits?
   - How did you determine these values?
   - When was the last time you reviewed them?

2. **Monitoring:**
   - Can you see actual resource usage vs limits?
   - Do you have alerts for OOMKilled events?
   - Do you track CPU throttling?

3. **Scaling:**
   - Do you use Horizontal Pod Autoscaling?
   - How do your applications handle traffic spikes?
   - What happens when you hit resource limits?

4. **Past Issues:**
   - Have you experienced OOMKilled pods?
   - What was the root cause?
   - How did you determine the right limits?

5. **Cost vs Performance:**
   - Are you over-provisioning resources?
   - Where could you reduce without risk?
   - Where should you increase for reliability?

---

## What's Next?

Sarah now understood resource management. She could:
- Set appropriate requests and limits
- Use HPA for automatic scaling
- Monitor and alert on resource issues
- Prevent OOMKilled and throttling

But there was one more challenge in Part I: the CI/CD pipeline. Deployments still took 2+ hours, builds frequently failed, and the pipeline consumed excessive resources. Sarah needed to learn about pipeline optimization.

In Chapter 5, "The Slow Release Nightmare," Sarah will learn how to optimize CI/CD pipelines for speed and reliability.

---

## Code Examples

All code examples from this chapter are available in the `examples/chapter-04/` directory of the GitHub repository.

**To access the examples:**

```bash
# Clone the repository
git clone https://github.com/BahaTanvir/devops-guide-book.git
cd devops-guide-book/examples/chapter-04

# See available files
ls -la

# Try the examples
kubectl apply -f resource-examples/
```

**What's included:**
- Resource limit examples (various patterns)
- HPA configurations
- Resource quota examples
- Monitoring queries
- Load testing scripts
- Memory profiling tools

**Online access:** [View examples on GitHub](https://github.com/BahaTanvir/devops-guide-book/tree/main/examples/chapter-04)

Remember: Proper resource management prevents outages and saves money! 💰
