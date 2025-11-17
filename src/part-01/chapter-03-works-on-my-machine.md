# Chapter 3: "It Works on My Machine"

> *"Environment parity isn't optional—it's fundamental."*

---

## What You'll Learn

Sarah's service works perfectly in staging but fails in production—classic environment drift. By the end of this chapter, you'll know how to:

- Identify common sources of environment drift between dev, staging, and production
- Apply the Twelve‑Factor App config principle in real deployment scenarios
- Use tools like Kustomize to separate base manifests from environment‑specific overlays
- Design a configuration audit and validation process that fails fast on missing config
- Choose appropriate strategies for managing secrets across environments
- Treat configuration as code with reviewable, repeatable deployments

---

## Sarah's Challenge

Three weeks had passed since Sarah set up the centralized logging system. The team was now able to debug issues much faster with Loki and structured logs. Sarah felt more confident—until Friday afternoon.

Marcus, the engineering manager, stopped by Sarah's desk. "Hey Sarah, we need to deploy the new notification service to production. It's been tested in staging and looks good. Can you handle the deployment?"

"Sure!" Sarah said confidently. She had deployed several services now and felt comfortable with the process.

She pulled up the deployment manifest and reviewed it:

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
        image: techflow/notification-service:v1.2.0
        ports:
        - containerPort: 8080
        env:
        - name: PORT
          value: "8080"
        - name: REDIS_URL
          value: "redis://redis:6379"
```

Everything looked standard. The same configuration had worked perfectly in staging. Sarah deployed to production:

```bash
kubectl apply -f notification-service.yaml -n production
```

The deployment completed successfully. Pods were running. Health checks passed. Sarah marked the task as done in Jira and went home for the weekend feeling accomplished.

Monday morning, she arrived to an urgent message:

```
@sarah Notification service is broken in production
- Emails not being sent
- Push notifications failing
- No errors in logs
- Staging still works fine!
```

Sarah's heart sank. How could this be? It worked perfectly in staging! She quickly checked the production logs:

```bash
kubectl logs deployment/notification-service -n production | grep -i error
```

No errors. The service was running, responding to health checks, but simply not sending notifications. She checked staging:

```bash
kubectl logs deployment/notification-service -n staging | grep -i notification
```

```json
{"level":"INFO","message":"Email sent successfully","recipient":"user@example.com"}
{"level":"INFO","message":"Push notification delivered","device_id":"abc123"}
```

Staging was working perfectly. Production was running but doing nothing. 

James walked over. "The classic 'works on my machine' problem. Or in this case, 'works in staging.' Let's figure out what's different."

---

## Understanding the Problem

Sarah's situation is one of the most common and frustrating issues in software deployment: **environment drift**. The code is identical, the deployment manifests look the same, but the behavior is completely different.

### 1. The Environment Parity Problem

Environment parity means keeping development, staging, and production environments as similar as possible. When environments drift, you get unpredictable behavior.

**Three Types of Parity:**

**Dev/Prod Parity (The Twelve-Factor App):**
- **Time:** Reduce time between writing code and deploying
- **Personnel:** Developers who write code should deploy it
- **Tools:** Keep development and production tools as similar as possible

**Common Drift Scenarios:**
```
Local     →  Staging   →  Production
SQLite       PostgreSQL   PostgreSQL (different version)
ENV vars     ConfigMap    Secrets
Mock APIs    Real APIs    Real APIs (different endpoints)
Single node  3 nodes      10 nodes
```

### 2. Configuration Drift

Configuration is the #1 source of environment differences. Sarah's notification service had different configurations in staging vs production that she didn't realize:

**Staging Configuration (working):**
```yaml
env:
- name: REDIS_URL
  value: "redis://redis:6379"
- name: SMTP_HOST
  value: "mailhog:1025"  # Test mail server
- name: SMTP_USER
  value: "test"
- name: SMTP_PASS
  value: "test"
- name: PUSH_API_KEY
  value: "test-key-12345"
```

**Production Configuration (Sarah's deployment - broken):**
```yaml
env:
- name: REDIS_URL
  value: "redis://redis:6379"
# Missing: SMTP_HOST, SMTP_USER, SMTP_PASS
# Missing: PUSH_API_KEY
```

The service didn't crash because it had default behavior: if configuration is missing, silently fail and log nothing. This is poor application design, but a common reality.

### 3. The Configuration Management Problem

TechFlow was managing configuration in multiple ways:

**Method 1: Hardcoded in Deployment (Bad)**
```yaml
env:
- name: PORT
  value: "8080"  # Hardcoded
```

**Method 2: Direct values (Better, still not great)**
```yaml
env:
- name: REDIS_URL
  value: "redis://redis:6379"  # Different per environment
```

**Method 3: ConfigMaps (Better)**
```yaml
env:
- name: REDIS_URL
  valueFrom:
    configMapKeyRef:
      name: notification-config
      key: redis-url
```

**Method 4: Secrets (Best for sensitive data)**
```yaml
env:
- name: SMTP_PASS
  valueFrom:
    secretKeyRef:
      name: notification-secrets
      key: smtp-password
```

**The Problem:** Different approaches in different environments made it hard to track what was configured where.

### 4. The Secrets Problem

Secrets are particularly tricky:
- Can't be checked into Git (security risk)
- Different in every environment
- Easy to forget during deployment
- Hard to verify without exposing values

Sarah's staging environment had secrets configured months ago by another engineer. Production was missing them, and she had no way to know.

### 5. Dependencies and Service Discovery

Services depend on other services. These dependencies can differ between environments:

```
Notification Service depends on:
- Redis (cache)
- SMTP Server (email)
- Push Notification API (mobile notifications)
- User Service (to get user preferences)
```

**Staging:**
- Redis: `redis.staging.svc.cluster.local:6379`
- SMTP: `mailhog.staging.svc.cluster.local:1025` (test server)
- Push API: Test API with mock responses
- User Service: Staging version with test data

**Production:**
- Redis: `redis.production.svc.cluster.local:6379`
- SMTP: `smtp.sendgrid.net:587` (real email service)
- Push API: Production API requiring real credentials
- User Service: Production version with real user data

If any of these URLs or credentials are wrong, the service fails silently.

### 6. The Twelve-Factor App Methodology

The Twelve-Factor App is a methodology for building modern applications. Factor III is particularly relevant:

**III. Config - Store config in the environment**

> An app's config is everything that is likely to vary between deploys (staging, production, developer environments, etc).

**Strict separation of config from code:**
- Config varies across deploys
- Code does not
- Config includes: database URLs, credentials, service endpoints
- Config should never be checked into version control

---

## The Senior's Perspective

James explained his approach to environment configuration.

### Configuration Mental Model

"Think of configuration in layers," James said, drawing on the whiteboard:

```
Layer 1: Application Defaults (in code)
         ↓ (overridden by)
Layer 2: Environment Variables
         ↓ (overridden by)
Layer 3: ConfigMaps/Files
         ↓ (overridden by)
Layer 4: Secrets
         ↓ (overridden by)
Layer 5: Command-line flags (if needed)
```

"Each layer should override the previous. And critically: **never, ever hardcode environment-specific values in your application code or deployment manifests.**"

### Questions Senior Engineers Ask About Configuration

1. **"What varies between environments?"**
   - Database URLs
   - API endpoints
   - API keys and secrets
   - Feature flags
   - Resource limits
   - Replica counts
   - Log levels

2. **"How do I verify all config is present?"**
   - Use admission webhooks
   - Application startup validation
   - Pre-deployment checks
   - Config validation tools

3. **"How do I prevent config drift?"**
   - Use GitOps (config in Git)
   - Infrastructure as Code (Terraform, Helm)
   - Configuration templates
   - Environment promotion pipeline

4. **"How do I manage secrets safely?"**
   - External secret managers (Vault, AWS Secrets Manager)
   - Encrypted secrets in Git (Sealed Secrets, SOPS)
   - Rotation policies
   - Least-privilege access

5. **"How do I test configuration?"**
   - Dry-run deployments
   - Integration tests per environment
   - Smoke tests post-deployment
   - Configuration validation tools

### Configuration Management Approaches

James explained TechFlow's options:

**Option 1: Environment-Specific Manifests**
```
deployments/
  ├── notification-service-dev.yaml
  ├── notification-service-staging.yaml
  └── notification-service-production.yaml
```
- **Pros:** Simple, explicit
- **Cons:** Duplication, drift risk, maintenance burden

**Option 2: Kustomize (Overlays)**
```
notification-service/
  ├── base/
  │   ├── deployment.yaml
  │   └── kustomization.yaml
  └── overlays/
      ├── staging/
      │   └── kustomization.yaml
      └── production/
          └── kustomization.yaml
```
- **Pros:** DRY, built into kubectl, simple
- **Cons:** Limited templating, learning curve

**Option 3: Helm (Charts)**
```
notification-service/
  ├── Chart.yaml
  ├── values.yaml
  ├── values-staging.yaml
  ├── values-production.yaml
  └── templates/
      ├── deployment.yaml
      └── service.yaml
```
- **Pros:** Powerful templating, package management
- **Cons:** Complex, can be overused, "Helm hell"

**Option 4: External Configuration (Recommended for TechFlow)**
```
Combine:
- Helm for templating
- External Secrets Operator for secrets
- GitOps (ArgoCD/Flux) for deployment
```

"For TechFlow," James said, "we'll use Kustomize. It's simple, built into kubectl, and solves 80% of our needs without the complexity of Helm."

---

## The Solution

James and Sarah implemented a proper configuration management system.

### Step 1: Audit Current Configuration

First, they documented what actually varied between environments:

```markdown
# Configuration Audit

## Notification Service Configuration

### Varies by Environment:
- SMTP credentials (username, password, host, port)
- Push notification API key
- Redis URL
- User service endpoint
- Log level
- Replica count

### Same Across Environments:
- Port (8080)
- Health check paths
- Base image
- Resource requests (tuned per environment later)

### Missing in Production:
- SMTP_HOST ❌
- SMTP_PORT ❌
- SMTP_USER ❌
- SMTP_PASS ❌
- PUSH_API_KEY ❌
```

### Step 2: Create Base Configuration with Kustomize

We'll start with a minimal but realistic base that is shared across environments, then layer environment‑specific differences on top.

> **Tip**
> If you're new to Kustomize, don't worry about memorizing every detail. Focus on the idea that you define a **base** once and then apply **small patches** per environment.

**Directory Structure (Conceptual):**
```text
notification-service/
├── base/
│   ├── deployment.yaml
│   ├── service.yaml
│   ├── configmap.yaml
│   └── kustomization.yaml
└── overlays/
    ├── staging/
    │   ├── kustomization.yaml
    │   ├── configmap-patch.yaml
    │   └── secrets.yaml
    └── production/
        ├── kustomization.yaml
        ├── configmap-patch.yaml
        └── resources-patch.yaml
```

**base/deployment.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notification-service
spec:
  replicas: 2  # Will be overridden per environment
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
        image: techflow/notification-service:v1.2.0
        ports:
        - containerPort: 8080
          name: http
        env:
        # Non-sensitive config from ConfigMap
        - name: PORT
          valueFrom:
            configMapKeyRef:
              name: notification-config
              key: port
        - name: REDIS_URL
          valueFrom:
            configMapKeyRef:
              name: notification-config
              key: redis-url
        - name: USER_SERVICE_URL
          valueFrom:
            configMapKeyRef:
              name: notification-config
              key: user-service-url
        - name: LOG_LEVEL
          valueFrom:
            configMapKeyRef:
              name: notification-config
              key: log-level
        # Sensitive config from Secrets
        - name: SMTP_HOST
          valueFrom:
            secretKeyRef:
              name: notification-secrets
              key: smtp-host
        - name: SMTP_PORT
          valueFrom:
            secretKeyRef:
              name: notification-secrets
              key: smtp-port
        - name: SMTP_USER
          valueFrom:
            secretKeyRef:
              name: notification-secrets
              key: smtp-user
        - name: SMTP_PASS
          valueFrom:
            secretKeyRef:
              name: notification-secrets
              key: smtp-password
        - name: PUSH_API_KEY
          valueFrom:
            secretKeyRef:
              name: notification-secrets
              key: push-api-key
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
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

**base/configmap.yaml:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: notification-config
data:
  port: "8080"
  # These will be overridden by environment-specific values
  redis-url: "OVERRIDE"
  user-service-url: "OVERRIDE"
  log-level: "INFO"
```

**base/kustomization.yaml:**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

resources:
  - deployment.yaml
  - service.yaml
  - configmap.yaml

commonLabels:
  app: notification-service
```

### Step 3: Create Staging Overlay

**overlays/staging/configmap-patch.yaml:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: notification-config
  # Kustomize will merge this with the base ConfigMap
  # based on name+namespace

data:
  port: "8080"
  redis-url: "redis://redis.staging.svc.cluster.local:6379"
  user-service-url: "http://user-service.staging.svc.cluster.local"
  log-level: "DEBUG"  # More verbose in staging
```

**overlays/staging/secrets.yaml:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: notification-secrets
  # In real systems you would not commit real secret values; this is for illustration.
type: Opaque
stringData:
  smtp-host: "mailhog.staging.svc.cluster.local"
  smtp-port: "1025"
  smtp-user: "test"
  smtp-password: "test"
  push-api-key: "test-key-staging-12345"
```

**overlays/staging/kustomization.yaml:**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: staging

resources:
  - ../../base
  - secrets.yaml

# Patch the base ConfigMap with staging‑specific values
patchesStrategicMerge:
  - configmap-patch.yaml

# Environment-specific Secret manifest
# (in real systems you wouldn't commit real secret values)
# Override replica count for staging
replicas:
  - name: notification-service
    count: 2

# Pin the image tag for this environment
images:
  - name: techflow/notification-service
    newTag: v1.2.0
```

### Step 4: Create Production Overlay

**overlays/production/configmap-patch.yaml:**
```yaml
apiVersion: v1
kind: ConfigMap
metadata:
  name: notification-config

data:
  port: "8080"
  redis-url: "redis://redis.production.svc.cluster.local:6379"
  user-service-url: "http://user-service.production.svc.cluster.local"
  log-level: "INFO"  # Less verbose in production
```

**overlays/production/secrets.yaml:**
```yaml
apiVersion: v1
kind: Secret
metadata:
  name: notification-secrets
  # Do not commit real production secrets to Git. Use this only in a demo environment,
  # and prefer tools like External Secrets Operator, Sealed Secrets, or Vault in practice.
type: Opaque
stringData:
  smtp-host: "smtp.sendgrid.net"
  smtp-port: "587"
  smtp-user: "apikey"
  smtp-password: "SG.REAL_API_KEY_HERE"  # Placeholder for real credentials
  push-api-key: "prod-push-api-key-real-12345"
```

**overlays/production/resources-patch.yaml:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: notification-service

spec:
  template:
    spec:
      containers:
      - name: notification
        resources:
          requests:
            memory: "512Mi"  # More resources in production
            cpu: "500m"
          limits:
            memory: "1Gi"
            cpu: "1000m"
```

**overlays/production/kustomization.yaml:**
```yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: production

resources:
  - ../../base
  - secrets.yaml

patchesStrategicMerge:
  - configmap-patch.yaml
  - resources-patch.yaml

# Environment-specific Secret manifest
replicas:
  - name: notification-service
    count: 5  # More replicas in production

images:
  - name: techflow/notification-service
    newTag: v1.2.0
```

### Step 5: Deploy with Kustomize

> **Deep Dive: Validating Kustomize Output**
> Before applying to a real cluster, always inspect the rendered manifests. This catches mistakes in patches and generators early.

**To Staging:**
```bash
# Preview what will be deployed
kubectl kustomize overlays/staging

# Apply to staging
kubectl apply -k overlays/staging

# Verify
kubectl get pods -n staging -l app=notification-service
kubectl logs -n staging -l app=notification-service | grep -i "Configuration loaded"
```

**To Production:**
```bash
# Preview
kubectl kustomize overlays/production

# Apply
kubectl apply -k overlays/production

# Verify
kubectl get pods -n production -l app=notification-service
kubectl logs -n production -l app=notification-service | tail -20
```

### Step 6: Improve Application Configuration Validation

James also showed Sarah how to improve the application itself to fail fast when configuration is missing:

**Before (Silent Failure):**
```python
# notification_service.py
smtp_host = os.getenv('SMTP_HOST', '')  # Defaults to empty
smtp_user = os.getenv('SMTP_USER', '')

def send_email(to, subject, body):
    if not smtp_host:
        logger.warning("SMTP not configured, skipping email")
        return  # Silent failure
```

**After (Fail Fast):**
```python
# notification_service.py
def validate_config():
    """Validate required configuration on startup"""
    required_vars = {
        'SMTP_HOST': os.getenv('SMTP_HOST'),
        'SMTP_PORT': os.getenv('SMTP_PORT'),
        'SMTP_USER': os.getenv('SMTP_USER'),
        'SMTP_PASS': os.getenv('SMTP_PASS'),
        'PUSH_API_KEY': os.getenv('PUSH_API_KEY'),
        'REDIS_URL': os.getenv('REDIS_URL'),
    }
    
    missing = [k for k, v in required_vars.items() if not v]
    
    if missing:
        logger.error(f"Missing required configuration: {missing}")
        sys.exit(1)  # Fail fast!
    
    logger.info("Configuration validated successfully")
    logger.info(f"SMTP Host: {required_vars['SMTP_HOST']}")  # Log (not password!)
    logger.info(f"Redis URL: {required_vars['REDIS_URL']}")

# Call during application startup
if __name__ == '__main__':
    validate_config()
    app.run()
```

Now if configuration is missing, the pod won't even start, and readiness checks will fail. Much better than silent failure!

### Step 7: Create Configuration Checklist

Sarah created a deployment checklist to prevent future issues:

```markdown
# Deployment Checklist

## Pre-Deployment

- [ ] All required ConfigMaps exist in target environment
- [ ] All required Secrets exist in target environment  
- [ ] ConfigMap/Secret values are correct for environment
- [ ] Application validates configuration on startup
- [ ] Dry-run deployment succeeds: `kubectl apply --dry-run=server -k overlays/<env>`
- [ ] Resource limits appropriate for environment

## Deployment

- [ ] Use Kustomize overlays: `kubectl apply -k overlays/<env>`
- [ ] Watch deployment: `kubectl rollout status deployment/<name> -n <namespace>`
- [ ] Check pod logs for configuration validation
- [ ] Verify all pods are Ready

## Post-Deployment

- [ ] Run smoke tests
- [ ] Check application logs for errors
- [ ] Verify integration with dependencies (Redis, SMTP, etc.)
- [ ] Monitor metrics for anomalies
- [ ] Test critical user flows

## Rollback Plan

- [ ] Previous version number: ___________
- [ ] Rollback command: `kubectl rollout undo deployment/<name> -n <namespace>`
- [ ] Verification steps: ___________
```

---

## Lessons Learned

Sarah documented the key lessons about environment configuration:

### 1. "Works on My Machine" Is Always Configuration

**The Lesson:**
When code works in one environment but not another, it's almost always configuration, not code.

**Common Culprits:**
- Missing environment variables
- Wrong service URLs
- Missing credentials
- Different dependency versions
- Resource constraints
- Network policies

**How to Debug:**
```bash
# Compare configurations
kubectl get configmap <name> -n staging -o yaml > staging-config.yaml
kubectl get configmap <name> -n production -o yaml > production-config.yaml
diff staging-config.yaml production-config.yaml

# Compare secrets (names only, not values)
kubectl get secrets -n staging
kubectl get secrets -n production

# Check environment variables in pod
kubectl exec -it <pod> -n <namespace> -- env | sort
```

### 2. Fail Fast on Missing Configuration

**The Lesson:**
Applications should validate configuration on startup and fail immediately if something is wrong.

**Implementation:**
```python
def validate_config():
    required = ['DATABASE_URL', 'API_KEY', 'REDIS_URL']
    missing = [var for var in required if not os.getenv(var)]
    
    if missing:
        print(f"ERROR: Missing required config: {missing}")
        sys.exit(1)

# Run before starting the application
validate_config()
app.run()
```

**Benefits:**
- Pods won't become Ready if config is wrong
- Clear error messages
- Fast feedback
- Prevents silent failures

### 3. Use Configuration Management Tools

**The Lesson:**
Don't manually manage environment-specific configuration. Use tools.

**Tool Options:**

**Kustomize (Recommended for most):**
```bash
# Simple, built into kubectl
kubectl apply -k overlays/production
```

**Helm:**
```bash
# Powerful templating
helm install myapp ./chart -f values-production.yaml
```

**Terraform + Kubernetes Provider:**
```hcl
# Infrastructure as Code
resource "kubernetes_config_map" "app_config" {
  # ...
}
```

### 4. Separate Config from Code

**The Lesson:**
Configuration should never be hardcoded in application code or deployment manifests.

**Bad (Hardcoded):**
```yaml
env:
- name: DATABASE_URL
  value: "postgresql://prod-db:5432/myapp"  # Hardcoded!
```

**Good (ConfigMap):**
```yaml
env:
- name: DATABASE_URL
  valueFrom:
    configMapKeyRef:
      name: app-config
      key: database-url
```

**Better (External Secrets):**
```yaml
env:
- name: DATABASE_URL
  valueFrom:
    secretKeyRef:
      name: app-secrets
      key: database-url
```

### 5. Secrets Are Special

**The Lesson:**
Secrets require special handling—never commit them to Git.

**Secret Management Options:**

**Option 1: Manual Creation (Development only)**
```bash
kubectl create secret generic app-secrets \
  --from-literal=api-key=abc123 \
  -n production
```

**Option 2: Sealed Secrets (Encrypted in Git)**
```bash
# Encrypt secret
kubeseal -f secret.yaml -w sealed-secret.yaml

# Commit sealed-secret.yaml to Git
# It decrypts automatically in cluster
```

**Option 3: External Secrets Operator (Recommended)**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: app-secrets
spec:
  secretStoreRef:
    name: aws-secrets-manager
  target:
    name: app-secrets
  data:
    - secretKey: api-key
      remoteRef:
        key: prod/app/api-key
```

**Option 4: HashiCorp Vault**
```yaml
# Inject secrets at runtime
annotations:
  vault.hashicorp.com/agent-inject: "true"
  vault.hashicorp.com/role: "myapp"
  vault.hashicorp.com/agent-inject-secret-config: "secret/data/myapp"
```

### 6. Environment Parity Reduces Risk

**The Lesson:**
The more similar staging is to production, the fewer surprises you'll have.

**Parity Checklist:**
- [ ] Same Kubernetes version
- [ ] Same resource limits (scaled down is OK)
- [ ] Same configuration structure (ConfigMaps, Secrets)
- [ ] Same dependency versions (Redis, PostgreSQL, etc.)
- [ ] Same networking setup
- [ ] Same monitoring and logging

**Acceptable Differences:**
- Replica counts (fewer in staging)
- Resource amounts (less in staging)
- Data volume (smaller in staging)
- External service endpoints (test vs production)

### 7. Configuration as Code

**The Lesson:**
Treat configuration like code—version controlled, reviewed, tested.

**Best Practices:**
```
✅ Store configuration in Git
✅ Require PR reviews for changes
✅ Test configuration changes in staging first
✅ Automate deployment with CI/CD
✅ Use GitOps for deployment
✅ Tag/version configuration changes
```

**Git Structure:**
```
infrastructure/
├── applications/
│   ├── notification-service/
│   │   ├── base/
│   │   └── overlays/
│   │       ├── staging/
│   │       └── production/
│   └── user-service/
└── README.md
```

### 8. Document Environment Differences

**The Lesson:**
Create a "source of truth" document listing all environment differences.

**Example Documentation:**
```markdown
# Environment Configuration Matrix

| Component | Development | Staging | Production |
|-----------|------------|---------|------------|
| Database | SQLite | PostgreSQL 14 | PostgreSQL 14 |
| Redis | Local | redis:6379 | redis-cluster:6379 |
| Replicas | 1 | 2 | 5 |
| CPU Limit | 100m | 500m | 1000m |
| Memory Limit | 128Mi | 512Mi | 1Gi |
| Log Level | DEBUG | DEBUG | INFO |
| SMTP | Mailhog | Mailhog | SendGrid |

## Secrets Required

### Staging
- smtp-password (test value)
- push-api-key (test key)

### Production  
- smtp-password (SendGrid API key)
- push-api-key (OneSignal production key)
- database-password (RDS password)
```

---

## Reflection Questions

Think about configuration management in your environment:

1. **Your Configuration Practice:**
   - How do you manage configuration across environments?
   - Are configurations in version control?
   - How similar are your staging and production environments?

2. **"Works on My Machine" Incidents:**
   - When was the last time something worked in one environment but not another?
   - What was the root cause?
   - How could it have been prevented?

3. **Secrets Management:**
   - Where do you store secrets?
   - Are secrets in Git? (They shouldn't be!)
   - How do you rotate secrets?

4. **Environment Differences:**
   - What varies between your environments?
   - Is this documented?
   - Are the differences intentional or accidental?

5. **Configuration Validation:**
   - Do your applications validate configuration on startup?
   - What happens when configuration is missing?
   - How quickly can you detect configuration issues?

6. **Tools and Processes:**
   - Do you use Kustomize, Helm, or another tool?
   - How do you deploy to different environments?
   - Is deployment automated or manual?

---

## What's Next?

Sarah now had proper configuration management in place. She could:
- Deploy the same application to any environment
- Know exactly what varies between environments
- Quickly identify configuration issues
- Avoid "works on my machine" problems

But she was about to face a new challenge: the notification service was running perfectly in production, but during a traffic spike, it started crashing. The logs showed `OOMKilled` errors. Sarah needed to learn about resource management in Kubernetes.

In Chapter 4, "The Resource Crunch," Sarah will learn about CPU and memory limits, how to rightsize applications, and how to prevent resource-related outages.

---

## Code Examples

All code examples from this chapter are available in the `examples/chapter-03/` directory of the GitHub repository.

**To access the examples:**

```bash
# Clone the repository
git clone https://github.com/BahaTanvir/devops-guide-book.git
cd devops-guide-book/examples/chapter-03

# See available files
ls -la

# Try deploying with Kustomize
kubectl apply -k overlays/staging --dry-run=client

# Deploy to local cluster
kubectl apply -k overlays/staging
```

**What's included:**
- Complete Kustomize base and overlays
- Configuration validation script
- Environment comparison tool
- Deployment checklist template
- Example applications with config validation
- Testing scripts

**Online access:** [View examples on GitHub](https://github.com/BahaTanvir/devops-guide-book/tree/main/examples/chapter-03)

Remember: Proper configuration management prevents 90% of deployment issues! 🔧
