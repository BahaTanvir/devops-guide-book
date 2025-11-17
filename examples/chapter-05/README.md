# Chapter 5: The Slow Release Nightmare

## Overview

Deployments take 2 hours and frequently fail midway. This chapter covers:

- CI/CD pipeline optimization
- Build caching strategies
- Parallel execution
- Artifact management
- Pipeline as code best practices

## Files

### Dockerfiles
- `dockerfiles/before-slow.dockerfile` - Slow, unoptimized Dockerfile (anti-pattern)
- `dockerfiles/after-optimized.dockerfile` - Optimized multi-stage Dockerfile
- `dockerfiles/.dockerignore` - Proper Docker ignore patterns

### CI/CD Pipelines
- `github-actions/slow-pipeline.yml` - Slow sequential pipeline (before)
- `github-actions/fast-pipeline.yml` - Optimized parallel pipeline (after)
- `gitlab-ci/.gitlab-ci.yml` - GitLab CI example with caching

### Scripts
- `scripts/smoke-test.sh` - Quick smoke tests for deployments

## Prerequisites

- Docker installed locally
- Access to a container registry (Docker Hub, GHCR, etc.)
- GitHub or GitLab account (for CI/CD examples)
- Basic understanding of Git workflows

## Quick Start

### 1. Compare Dockerfiles

```bash
# Build the slow Dockerfile
cd dockerfiles/
docker build -f before-slow.dockerfile -t myapp:slow .

# Build the optimized Dockerfile
docker build -f after-optimized.dockerfile -t myapp:fast .

# Compare image sizes
docker images | grep myapp
```

**Expected Results:**
- Slow build: ~500MB, takes 5+ minutes on first build
- Fast build: ~150MB, takes 2 minutes on first build, 30s with cache

### 2. Test Layer Caching

```bash
# First build (no cache)
time docker build -f after-optimized.dockerfile -t myapp:v1 .

# Make a code change (doesn't affect dependencies)
echo "// comment" >> src/index.js

# Second build (should use cache for dependency layers)
time docker build -f after-optimized.dockerfile -t myapp:v2 .
```

**Expected:** Second build should be much faster (cache hit on dependency layers)

### 3. Test GitHub Actions Locally

```bash
# Install act (GitHub Actions local runner)
# macOS: brew install act
# Linux: see https://github.com/nektos/act

# Test the fast pipeline
act -W github-actions/fast-pipeline.yml

# Compare with slow pipeline
act -W github-actions/slow-pipeline.yml
```

### 4. Analyze Docker Build

```bash
# Build with progress output
docker build -f after-optimized.dockerfile -t myapp:analyzed . --progress=plain

# Look for:
# - Layer cache hits (CACHED)
# - Large file transfers
# - Time spent on each step
```

### 5. Run Smoke Tests

```bash
# Start a container
docker run -d -p 3000:3000 --name myapp myapp:fast

# Run smoke tests
./scripts/smoke-test.sh

# Cleanup
docker stop myapp && docker rm myapp
```

## Learning Objectives

After completing these examples, you will understand:

1. **Docker Optimization**
   - Layer caching and cache invalidation
   - Multi-stage builds to reduce image size
   - Proper ordering of Dockerfile instructions
   - Using .dockerignore to exclude unnecessary files

2. **CI/CD Pipeline Speed**
   - Identify pipeline bottlenecks (critical path analysis)
   - Parallelize independent jobs
   - Use caching for dependencies and build artifacts
   - Optimize test execution with test splitting

3. **Build Strategies**
   - Separate build dependencies from runtime dependencies
   - Use slim/alpine base images
   - Implement incremental builds
   - Cache Docker layers in CI/CD

4. **Fast Feedback Loops**
   - Run fast tests first (fail-fast principle)
   - Use smoke tests for quick validation
   - Implement staged rollouts (dev → staging → prod)
   - Balance speed with safety

## Performance Comparison

### Before Optimization
```
Pipeline Time: 45 minutes
├── Checkout: 30s
├── Build (sequential): 15 min
│   ├── Install deps: 8 min
│   ├── Lint: 2 min
│   ├── Test: 5 min
├── Docker Build: 10 min
├── Push: 2 min
├── Deploy Dev: 5 min
├── Deploy Staging: 5 min (waits for dev)
└── Deploy Prod: 5 min (waits for staging)

Total: ~45 minutes
```

### After Optimization
```
Pipeline Time: 12 minutes
├── Checkout: 30s
├── Parallel Jobs: 6 min (runs simultaneously)
│   ├── Lint (cached): 1 min
│   ├── Unit Tests (cached): 2 min
│   ├── Integration Tests: 4 min
│   └── Build (cached layers): 3 min
├── Docker Build (multi-stage, cached): 2 min
├── Push (layer caching): 1 min
├── Parallel Deploys: 3 min
│   ├── Dev + Staging: 3 min (parallel)
└── Prod (after smoke test): 2 min

Total: ~12 minutes (73% faster!)
```

## Key Optimizations Explained

### 1. Docker Layer Caching
```dockerfile
# ❌ Bad: Copy everything, then install (cache breaks on any code change)
COPY . .
RUN npm install

# ✅ Good: Install dependencies first (cache survives code changes)
COPY package*.json ./
RUN npm ci --only=production
COPY . .
```

### 2. Multi-Stage Builds
```dockerfile
# Stage 1: Install all dependencies (including devDependencies)
FROM node:18 AS builder
RUN npm ci && npm run build

# Stage 2: Only production dependencies and built artifacts
FROM node:18-alpine AS runtime
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
```

**Result:** Final image is 50-70% smaller

### 3. Parallel CI Jobs
```yaml
# ❌ Bad: Sequential (total = sum of all times)
jobs:
  lint:
    runs-on: ubuntu-latest
  test:
    needs: lint  # Waits for lint
  build:
    needs: test  # Waits for test

# ✅ Good: Parallel (total = max of all times)
jobs:
  lint:
    runs-on: ubuntu-latest
  test:
    runs-on: ubuntu-latest
  build:
    runs-on: ubuntu-latest
```

### 4. Dependency Caching
```yaml
- uses: actions/setup-node@v3
  with:
    node-version: 18
    cache: 'npm'  # ✅ Caches node_modules
```

**Result:** 5-8 minute dependency install → 30 seconds

## Common Issues

### Issue: Docker cache not working
```bash
# Check what's invalidating cache
docker build --no-cache -f after-optimized.dockerfile -t myapp:test .
```

**Common causes:**
- Files changing that shouldn't (check .dockerignore)
- Package manager lock files not committed
- Timestamp-based operations in Dockerfile

### Issue: CI/CD still slow despite caching
```bash
# Check if cache is being restored
# In GitHub Actions, look for "Cache restored" in logs
```

**Solutions:**
- Verify cache key matches across runs
- Check cache size limits (GitHub: 10GB per repo)
- Use external cache services (BuildKit remote cache)

### Issue: Large Docker images
```bash
# Analyze image layers
docker history myapp:fast

# Find large layers
docker save myapp:fast | gzip > myapp.tar.gz
```

**Solutions:**
- Use multi-stage builds
- Use alpine or distroless base images
- Remove build tools from final image
- Combine RUN commands to reduce layers

## Additional Resources

- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)
- [GitHub Actions Caching](https://docs.github.com/en/actions/using-workflows/caching-dependencies-to-speed-up-workflows)
- [BuildKit Cache](https://docs.docker.com/build/cache/)
- [CI/CD Pipeline Optimization](https://www.atlassian.com/continuous-delivery/principles/pipeline-optimization)
