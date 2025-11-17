# Chapter 1: The Incident That Changed Everything

> *"The best teacher is experience, and the most memorable lessons come from production outages."*

---

## Sarah's Challenge

It was a Thursday afternoon, three months into her role at TechFlow, when Sarah experienced her first production incident. She had just finished lunch and was reviewing a pull request when her phone buzzed. Then again. And again.

The #incidents Slack channel was exploding with messages:

```
@channel CRITICAL: Checkout service is down
Multiple customer reports - cannot complete purchases
Revenue impact - immediate attention needed
```

Sarah's heart raced. She had deployed a new version of the checkout service just 20 minutes ago. The deployment had completed successfully—all green checkmarks in the CI/CD pipeline. She had even checked the pods, and they were running. What could have gone wrong?

"Sarah, did you just deploy checkout?" James, the senior DevOps engineer, appeared at her desk.

"Yes, about twenty minutes ago. Version 2.3.0. The deployment succeeded, and all pods are running," Sarah replied, her voice tight with anxiety.

"Let me take a look with you," James said calmly, pulling up a chair. "Show me what you deployed."

Sarah pulled up her terminal, fingers slightly trembling as she typed:

```bash
kubectl get pods -n production -l app=checkout-service
```

The output showed:

```
NAME                                READY   STATUS    RESTARTS   AGE
checkout-service-7d8f4c5b9d-8xk2p   1/1     Running   0          19m
checkout-service-7d8f4c5b9d-j7h9m   1/1     Running   0          19m
checkout-service-7d8f4c5b9d-m2p4w   1/1     Running   0          19m
```

"See? All three pods are running," Sarah said, confused.

"Running doesn't mean working," James said gently. "Let's check the logs."

```bash
kubectl logs checkout-service-7d8f4c5b9d-8xk2p -n production
```

The terminal filled with error messages:

```
Error: DATABASE_URL environment variable not set
Fatal: Cannot connect to database
Application startup failed
[1] 156 segmentation fault  ./checkout-service
```

Sarah's stomach dropped. "Oh no. I forgot to add the new database environment variable."

The new version of the checkout service required a `DATABASE_URL` environment variable that she had tested locally but never added to the Kubernetes deployment configuration. The pods started successfully because the container launched, but the application inside crashed immediately. Since there were no proper health checks configured, Kubernetes kept the pods in "Running" state even though they weren't serving any traffic.

"This is a perfect learning moment," James said. "Let's fix this and talk about what happened. First priority: restore service. Can you roll back?"

Sarah's mind went blank. "How do I roll back?"

---

## Understanding the Problem

Sarah's first incident revealed several common issues that junior DevOps engineers face:

### 1. The "Running" vs "Ready" Misconception

In Kubernetes, a pod can be in "Running" state without actually being able to serve traffic. Here's what happened:

- **Container Started**: The checkout service container launched successfully
- **Process Started**: The main application process started
- **Application Crashed**: The application immediately crashed due to missing configuration
- **Kubernetes Unaware**: Without proper health checks, Kubernetes had no way to know the application wasn't working

This is one of the most common sources of confusion for newcomers to Kubernetes. The pod status reflects the container runtime state, not the application health.

### 2. Missing Health Checks

Sarah's deployment had no health checks configured. Kubernetes supports three types of probes:

- **Liveness Probe**: Is the application alive? If not, restart the container
- **Readiness Probe**: Is the application ready to serve traffic? If not, remove from service endpoints
- **Startup Probe**: Has the application finished starting up? (For slow-starting applications)

Without these probes, Kubernetes assumes a running container is a healthy container—a dangerous assumption.

### 3. Configuration Drift Between Environments

The classic "works on my machine" problem manifested here:

- **Local Development**: Sarah set `DATABASE_URL` in her `.env` file
- **Staging**: The variable was configured in the staging deployment (she had tested there)
- **Production**: She forgot to add it to the production deployment manifest

This environment configuration drift is a frequent source of production issues.

### 4. Lack of Deployment Validation

The deployment succeeded from Kubernetes' perspective because:
- The deployment resource was valid YAML
- The pods were scheduled successfully
- The containers started

But there was no validation that the application was actually working correctly.

### 5. No Rollback Plan

When the incident occurred, Sarah didn't know how to quickly rollback. This extended the outage duration unnecessarily. Having a rollback plan is as important as the deployment itself.

---

## The Senior's Perspective

James walked Sarah through his mental model for handling deployment incidents:

### Incident Response Framework

"When an incident happens right after a deployment," James explained, "I follow a specific mental checklist:"

**1. Restore Service First (Incident Response)**
- Can we rollback immediately?
- What's the blast radius? (How many users affected?)
- Is there a quick mitigation without rollback?

**2. Gather Information (Diagnostic Phase)**
- What changed? (Recent deployments, config changes, traffic patterns)
- What are the symptoms? (Errors in logs, failed health checks, metrics anomalies)
- What's the timeline? (When did it start? Any correlation with events?)

**3. Understand the Root Cause**
- Why did the deployment succeed but the application fail?
- Why didn't our testing catch this?
- What safeguards should have prevented this?

**4. Prevent Recurrence**
- What process changes are needed?
- What automation can help?
- What monitoring would have caught this sooner?

### The Questions Senior Engineers Ask

James shared the questions he automatically asks during any deployment issue:

1. **"What does 'success' mean?"**
   - For Sarah, deployment success meant pods running
   - For James, success means users can complete their workflows

2. **"What are we not seeing?"**
   - The logs showed errors, but without looking, everything appeared fine
   - What metrics or alerts should have notified them immediately?

3. **"How quickly can we rollback?"**
   - Always know your rollback procedure before deploying
   - Practice rollbacks in staging

4. **"What's different between environments?"**
   - Configuration differences are the #1 cause of "works in staging but not production"
   - Environment parity is crucial

5. **"What will I learn from this?"**
   - Every incident is a learning opportunity
   - Post-mortems without blame lead to better systems

### The Deployment Safety Mental Model

James explained his framework for deployment safety:

```
Safe Deployment = Validation + Gradual Rollout + Health Checks + Easy Rollback
```

- **Validation**: Automated checks that the deployment is actually working
- **Gradual Rollout**: Don't update all instances at once (we'll cover strategies later)
- **Health Checks**: Let Kubernetes know if the application is healthy
- **Easy Rollback**: One command to undo changes

"The goal," James said, "isn't to never have incidents. It's to detect them quickly, resolve them fast, and learn from each one."

---

## The Solution

### Immediate Fix: Rolling Back

James showed Sarah the quickest way to rollback a Kubernetes deployment:

```bash
# View deployment history
kubectl rollout history deployment/checkout-service -n production

REVISION  CHANGE-CAUSE
1         Initial deployment v2.2.0
2         Update to v2.3.0 (current)

# Rollback to previous version
kubectl rollout undo deployment/checkout-service -n production

# Watch the rollback progress
kubectl rollout status deployment/checkout-service -n production
```

Within 30 seconds, the previous version was restored, and checkout functionality was working again. Sarah immediately posted to the #incidents channel:

```
Service restored via rollback to v2.2.0
Issue: Missing DATABASE_URL env var in production deployment
Post-mortem to follow
```

### Understanding What Happened

Let's look at what Sarah deployed vs. what she should have deployed.

**Sarah's Deployment (Broken):**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-service
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: checkout-service
  template:
    metadata:
      labels:
        app: checkout-service
    spec:
      containers:
      - name: checkout
        image: techflow/checkout-service:2.3.0
        ports:
        - containerPort: 8080
        env:
        - name: PORT
          value: "8080"
        # Missing: DATABASE_URL environment variable
```

**What She Should Have Deployed:**

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-service
  namespace: production
spec:
  replicas: 3
  selector:
    matchLabels:
      app: checkout-service
      version: v2.3.0  # Version label for tracking
  strategy:
    type: RollingUpdate
    rollingUpdate:
      maxSurge: 1        # Create 1 extra pod during rollout
      maxUnavailable: 0  # Ensure all replicas available during rollout
  template:
    metadata:
      labels:
        app: checkout-service
        version: v2.3.0
    spec:
      containers:
      - name: checkout
        image: techflow/checkout-service:2.3.0
        ports:
        - containerPort: 8080
        env:
        - name: PORT
          value: "8080"
        - name: DATABASE_URL
          valueFrom:
            secretKeyRef:
              name: checkout-secrets
              key: database-url
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        # Health checks - Critical!
        livenessProbe:
          httpGet:
            path: /health
            port: 8080
          initialDelaySeconds: 10
          periodSeconds: 10
          timeoutSeconds: 5
          failureThreshold: 3
        readinessProbe:
          httpGet:
            path: /ready
            port: 8080
          initialDelaySeconds: 5
          periodSeconds: 5
          timeoutSeconds: 3
          failureThreshold: 3
```

### Key Improvements Explained

**1. Environment Variable from Secret:**
```yaml
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: checkout-secrets
      key: database-url
```
- Retrieves the database URL from a Kubernetes Secret
- Keeps sensitive data out of the deployment manifest
- Can be managed separately per environment

**2. Resource Limits:**
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```
- `requests`: Minimum resources guaranteed to the pod
- `limits`: Maximum resources the pod can use
- Prevents one pod from starving others
- Helps Kubernetes schedule pods appropriately

**3. Liveness Probe:**
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 10
  failureThreshold: 3
```
- Kubernetes checks `/health` endpoint every 10 seconds
- If it fails 3 times, Kubernetes restarts the container
- Catches situations where the application is frozen or deadlocked

**4. Readiness Probe:**
```yaml
readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 5
  periodSeconds: 5
  failureThreshold: 3
```
- Kubernetes checks `/ready` endpoint every 5 seconds
- If it fails, the pod is removed from the Service endpoints (no traffic sent to it)
- Only passes when the application is ready to serve requests
- **This would have prevented Sarah's incident**: Pods without DATABASE_URL would never become Ready

**5. Rolling Update Strategy:**
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 0
```
- `maxSurge: 1`: Can create 1 extra pod during rollout (so with 3 replicas, temporarily have 4)
- `maxUnavailable: 0`: All original pods must be available during rollout
- This ensures zero downtime during deployments
- New pods must pass readiness checks before old pods are terminated

### Deployment Strategies Compared

James explained different deployment strategies and when to use each:

#### 1. Recreate Strategy
```yaml
strategy:
  type: Recreate
```

**How it works:**
- Terminate all old pods
- Then create new pods

**Pros:**
- Simple
- Guarantees no two versions running simultaneously

**Cons:**
- Downtime during transition
- Not acceptable for most production services

**When to use:**
- Development environments
- Services where downtime is acceptable
- Applications that can't run multiple versions simultaneously

#### 2. Rolling Update (Default)
```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1
    maxUnavailable: 1
```

**How it works:**
- Gradually replace old pods with new ones
- Can configure how many to update at once

**Pros:**
- Zero downtime if configured correctly
- Automatic rollback if new pods fail health checks
- Works for most use cases

**Cons:**
- Both versions running during rollout
- Slower than recreate

**When to use:**
- Most production deployments
- When zero downtime is required
- When health checks are properly configured

#### 3. Blue-Green Deployment

```yaml
# Blue (current production)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-service-blue
spec:
  replicas: 3
  selector:
    matchLabels:
      app: checkout-service
      version: blue
  template:
    metadata:
      labels:
        app: checkout-service
        version: blue
    spec:
      containers:
      - name: checkout
        image: techflow/checkout-service:2.2.0
---
# Green (new version)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-service-green
spec:
  replicas: 3
  selector:
    matchLabels:
      app: checkout-service
      version: green
  template:
    metadata:
      labels:
        app: checkout-service
        version: green
    spec:
      containers:
      - name: checkout
        image: techflow/checkout-service:2.3.0
---
# Service (switch between blue and green)
apiVersion: v1
kind: Service
metadata:
  name: checkout-service
spec:
  selector:
    app: checkout-service
    version: blue  # Change to 'green' to switch traffic
  ports:
  - port: 80
    targetPort: 8080
```

**How it works:**
- Run both versions in parallel
- Switch traffic by changing Service selector
- Keep old version running for quick rollback

**Pros:**
- Instant switchover
- Instant rollback
- Can test new version in production before switching traffic

**Cons:**
- Requires 2x resources during deployment
- More complex to manage

**When to use:**
- Critical services where instant rollback is essential
- When you have resources to run duplicate environments
- When you want to validate in production before switching traffic

#### 4. Canary Deployment

```yaml
# Stable deployment (90% of traffic)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-service-stable
spec:
  replicas: 9  # 90% of desired capacity
  selector:
    matchLabels:
      app: checkout-service
      track: stable
  template:
    metadata:
      labels:
        app: checkout-service
        track: stable
        version: v2.2.0
    spec:
      containers:
      - name: checkout
        image: techflow/checkout-service:2.2.0
---
# Canary deployment (10% of traffic)
apiVersion: apps/v1
kind: Deployment
metadata:
  name: checkout-service-canary
spec:
  replicas: 1  # 10% of desired capacity
  selector:
    matchLabels:
      app: checkout-service
      track: canary
  template:
    metadata:
      labels:
        app: checkout-service
        track: canary
        version: v2.3.0
    spec:
      containers:
      - name: checkout
        image: techflow/checkout-service:2.3.0
---
# Service sends traffic to both
apiVersion: v1
kind: Service
metadata:
  name: checkout-service
spec:
  selector:
    app: checkout-service  # Matches both stable and canary
  ports:
  - port: 80
    targetPort: 8080
```

**How it works:**
- Deploy new version to small subset of pods
- Monitor metrics and errors
- Gradually increase percentage if healthy
- Rollback immediately if issues detected

**Pros:**
- Limits blast radius of bad deployments
- Real production validation with minimal risk
- Can catch issues before full rollout

**Cons:**
- More complex to orchestrate
- Requires good monitoring to detect issues
- Takes longer to fully roll out

**When to use:**
- High-traffic services where you can detect issues quickly
- When you want to validate with real production traffic
- Services where a small percentage of errors is acceptable during validation

### Creating the Required Secret

Before deploying, Sarah needed to create the Secret containing the database URL:

```bash
# Create secret from literal value (for testing - not recommended for production)
kubectl create secret generic checkout-secrets \
  --from-literal=database-url='postgresql://user:pass@db.example.com:5432/checkout' \
  -n production

# Better: Create from file that's not in version control
echo 'postgresql://user:pass@db.example.com:5432/checkout' > /tmp/db-url
kubectl create secret generic checkout-secrets \
  --from-file=database-url=/tmp/db-url \
  -n production
rm /tmp/db-url

# Best: Use external secret management (covered in Chapter 24)
# Tools: Sealed Secrets, External Secrets Operator, Vault, etc.
```

### Deploying the Fix

With the corrected deployment manifest and secret created, Sarah could now deploy safely:

```bash
# Apply the corrected deployment
kubectl apply -f checkout-deployment.yaml -n production

# Watch the rollout
kubectl rollout status deployment/checkout-service -n production

# Check pod status
kubectl get pods -n production -l app=checkout-service

# Verify health checks are passing
kubectl describe pod <pod-name> -n production | grep -A 10 "Conditions:"

# Check application logs
kubectl logs -f deployment/checkout-service -n production

# Test the endpoint
kubectl port-forward service/checkout-service 8080:80 -n production
curl http://localhost:8080/health
curl http://localhost:8080/ready
```

### Monitoring the Deployment

James showed Sarah how to monitor deployments effectively:

```bash
# Watch deployment progress in real-time
kubectl get pods -n production -l app=checkout-service -w

# Check deployment events
kubectl describe deployment checkout-service -n production

# View recent events in the namespace
kubectl get events -n production --sort-by='.lastTimestamp' | head -20

# Check if new pods are ready
kubectl get deployment checkout-service -n production

# Output will show:
# NAME               READY   UP-TO-DATE   AVAILABLE   AGE
# checkout-service   3/3     3            3           5m
```

**Understanding the output:**
- `READY`: 3/3 means 3 of 3 replicas are ready (passing readiness probe)
- `UP-TO-DATE`: 3 pods are running the latest version
- `AVAILABLE`: 3 pods are available to serve traffic

If the readiness probe fails, you'd see something like:
```
NAME               READY   UP-TO-DATE   AVAILABLE   AGE
checkout-service   0/3     3            0           5m
```

This indicates the pods are running but failing readiness checks—exactly what Sarah's incident would have shown with proper health checks.

---

## Lessons Learned

After resolving the incident, Sarah and James had a post-mortem discussion. Here are the key lessons:

### 1. "Running" ≠ "Working"

**The Lesson:**
Never trust pod status alone. Always verify the application is actually healthy.

**How to Apply:**
- Always configure liveness and readiness probes
- Test health check endpoints thoroughly
- Monitor application-level metrics, not just infrastructure metrics

**Red Flags to Watch For:**
- Pods showing "Running" but service is down
- Deployment shows "complete" but errors are occurring
- No health check endpoints defined in your application

### 2. Health Checks Are Not Optional

**The Lesson:**
Health checks are the contract between your application and Kubernetes. Without them, Kubernetes is flying blind.

**How to Apply:**
```yaml
# Minimum viable health checks
livenessProbe:
  httpGet:
    path: /health
    port: 8080
  initialDelaySeconds: 30
  periodSeconds: 10

readinessProbe:
  httpGet:
    path: /ready
    port: 8080
  initialDelaySeconds: 10
  periodSeconds: 5
```

**What Health Checks Should Test:**
- **Liveness**: Is the application process alive? (Basic responsiveness)
- **Readiness**: Can the application serve traffic? (Database connected, dependencies available)

**Implementation Tips:**
```python
# Example in Python/Flask
@app.route('/health')
def health():
    # Simple liveness check
    return {'status': 'healthy'}, 200

@app.route('/ready')
def ready():
    # More thorough readiness check
    try:
        # Check database connection
        db.execute('SELECT 1')
        # Check required environment variables
        required_vars = ['DATABASE_URL', 'API_KEY']
        missing = [v for v in required_vars if not os.getenv(v)]
        if missing:
            return {'status': 'not ready', 'missing': missing}, 503
        return {'status': 'ready'}, 200
    except Exception as e:
        return {'status': 'not ready', 'error': str(e)}, 503
```

### 3. Configuration Management Is Critical

**The Lesson:**
Configuration drift between environments is a primary cause of "works in staging but not production" issues.

**How to Apply:**
- Use the same configuration mechanism across all environments
- Store configuration in version control (except secrets)
- Use tools like Helm, Kustomize, or Terraform to manage environment-specific values
- Validate configuration before deploying

**Pattern to Follow:**
```
# Base configuration (shared)
base/
  deployment.yaml
  service.yaml

# Environment-specific overlays
overlays/
  staging/
    kustomization.yaml  # Staging-specific values
  production/
    kustomization.yaml  # Production-specific values
```

### 4. Always Have a Rollback Plan

**The Lesson:**
Before deploying, know exactly how you'll rollback if something goes wrong.

**How to Apply:**
```bash
# Document rollback commands in your runbook
# Quick rollback
kubectl rollout undo deployment/<name> -n <namespace>

# Rollback to specific revision
kubectl rollout undo deployment/<name> --to-revision=2 -n <namespace>

# Verify rollback
kubectl rollout status deployment/<name> -n <namespace>
```

**Rollback Checklist:**
- [ ] Test rollback in staging first
- [ ] Verify rollback doesn't require database migrations
- [ ] Ensure monitoring is in place to detect if rollback fixed the issue
- [ ] Have runbook with exact commands ready
- [ ] Know who has authority to execute rollback

### 5. Deploy With Progressive Validation

**The Lesson:**
Don't deploy to all instances at once. Gradual rollouts catch issues before they affect everyone.

**Deployment Best Practices:**
1. **Start with canary** (1-10% of traffic)
2. **Monitor metrics** (errors, latency, resource usage)
3. **Gradually increase** if metrics look good
4. **Rollback immediately** if anomalies detected
5. **Full rollout** only after validation period

**Metrics to Monitor During Deployment:**
- Error rate (should not increase)
- Response time (p50, p95, p99)
- Request rate (should remain stable)
- Resource usage (CPU, memory)
- Custom business metrics (conversion rate, checkout completion)

### 6. Automate Validation

**The Lesson:**
Humans forget steps. Automation doesn't.

**What to Automate:**
```yaml
# In your CI/CD pipeline
steps:
  - name: Validate Deployment Manifest
    run: |
      # Check for required fields
      kubectl apply --dry-run=client -f deployment.yaml
      
  - name: Check for Required Secrets
    run: |
      # Verify secrets exist before deploying
      kubectl get secret checkout-secrets -n production
      
  - name: Run Smoke Tests
    run: |
      # After deployment, verify service works
      ./scripts/smoke-test.sh
      
  - name: Monitor for Errors
    run: |
      # Watch for 5 minutes, rollback if error rate spikes
      ./scripts/monitor-deployment.sh
```

### 7. Post-Mortems Without Blame

**The Lesson:**
The goal of a post-mortem is to improve systems, not to assign blame.

**Post-Mortem Template:**
```markdown
# Incident Post-Mortem: Checkout Service Outage

## Summary
- **Date:** 2024-01-18
- **Duration:** 20 minutes
- **Impact:** Checkout unavailable, ~$X revenue loss
- **Root Cause:** Missing environment variable in production deployment

## Timeline
- 14:05 - Deployment of v2.3.0 started
- 14:06 - Deployment marked "complete" by CI/CD
- 14:08 - First customer complaint received
- 14:10 - #incidents alert posted
- 14:12 - Issue identified (missing DATABASE_URL)
- 14:13 - Rollback initiated
- 14:14 - Service restored

## What Went Well
- Rollback was quick once issue identified
- Team communication was clear
- Customer support notified promptly

## What Went Wrong
- No health checks to catch the issue
- Configuration not validated before deployment
- Issue not caught in staging (why?)

## Action Items
- [ ] Add liveness and readiness probes (Sarah, by Friday)
- [ ] Implement pre-deployment validation script (James, next week)
- [ ] Sync production secrets to staging for accurate testing (Sarah + James)
- [ ] Update deployment runbook with rollback procedure
- [ ] Add automated smoke tests to CI/CD pipeline

## Lessons for the Team
- Health checks are mandatory for all services
- "Pods running" doesn't mean "service working"
- Always test rollback procedure
```

### 8. Deployment Readiness Checklist

**Before Every Production Deployment:**

```markdown
## Pre-Deployment Checklist

### Code & Configuration
- [ ] Code reviewed and approved
- [ ] All tests passing (unit, integration, e2e)
- [ ] Configuration validated in staging
- [ ] Secrets verified to exist in production
- [ ] Database migrations tested (if applicable)

### Health & Monitoring
- [ ] Health check endpoints implemented and tested
- [ ] Metrics and logging configured
- [ ] Alerts configured for new version
- [ ] Dashboard updated for monitoring deployment

### Deployment Strategy
- [ ] Deployment strategy chosen (rolling/blue-green/canary)
- [ ] Rollback procedure documented and tested
- [ ] Resource limits appropriate for expected load
- [ ] Deployment during low-traffic window (if possible)

### Communication
- [ ] Team notified of deployment
- [ ] Customer support aware (if customer-facing change)
- [ ] Incident response team on standby
- [ ] Post-deployment validation plan ready

### Validation
- [ ] Smoke tests ready to run post-deployment
- [ ] Monitoring in place to detect issues
- [ ] Success criteria defined
- [ ] Rollback triggers identified
```

---

## Reflection Questions

Take a moment to think about how these lessons apply to your own environment:

1. **Health Checks in Your Services**
   - Do all your production services have liveness and readiness probes configured?
   - What do your health check endpoints actually verify?
   - Have you tested what happens when health checks fail?

2. **Your Last Deployment**
   - What was your deployment strategy? (Recreate, rolling, blue-green, canary?)
   - How did you verify the deployment was successful?
   - How long would it take you to rollback right now?

3. **Configuration Management**
   - How do you manage environment-specific configuration?
   - How confident are you that staging matches production?
   - Where are your secrets stored, and who has access?

4. **Incident Response**
   - Does your team have a documented incident response process?
   - Who is responsible for production deployments?
   - How do you communicate during incidents?

5. **Learning from Incidents**
   - When was your last production incident?
   - Did you write a blameless post-mortem?
   - What systemic improvements came from it?

6. **Your Deployment Confidence**
   - On a scale of 1-10, how confident are you when deploying to production?
   - What would increase that confidence?
   - What keeps you up at night about your deployments?

---

## What's Next?

Sarah learned crucial lessons from her first incident:
- The difference between "running" and "working"
- The importance of health checks
- How to rollback quickly
- The value of blameless post-mortems

But this incident also revealed gaps in TechFlow's infrastructure:
- **Logs were hard to find** during the incident (Chapter 2)
- **Environment parity** between staging and production was questionable (Chapter 3)
- **Resource limits** weren't configured, which could cause other issues (Chapter 4)
- **Deployments took a long time** and could be optimized (Chapter 5)

In the next chapter, we'll follow Sarah as she faces another common challenge: the mystery of the disappearing logs. When debugging a production issue, she'll discover that the logs she needs aren't where she expects them to be—and sometimes aren't being collected at all.

---

## Code Examples

All the code examples from this chapter are available in the GitHub repository:

```bash
# Clone the repository
git clone https://github.com/BahaTanvir/devops-guide-book.git
cd devops-guide-book/examples/chapter-01

# Or if you already have the repo
cd examples/chapter-01
```

See the [Chapter 1 Examples README](https://github.com/BahaTanvir/devops-guide-book/tree/main/examples/chapter-01) for detailed instructions on running these examples in your own environment.

**Try it yourself:**
1. Deploy the broken version and observe the issue
2. Practice rolling back
3. Deploy the fixed version with health checks
4. Experiment with different deployment strategies
5. Intentionally break health checks to see Kubernetes' response

Remember: The best way to learn is by doing—in a safe, non-production environment! 🚀
