# Deployment Checklist

Use this checklist for every deployment to prevent configuration-related issues.

## Pre-Deployment

### Configuration Verification
- [ ] All required ConfigMaps exist in target environment
- [ ] All required Secrets exist in target environment
- [ ] ConfigMap values are correct for the environment
- [ ] Secret values are correct for the environment
- [ ] No hardcoded environment-specific values in code
- [ ] Configuration documented in environment matrix

### Application Readiness
- [ ] Application validates configuration on startup
- [ ] Health check endpoint implemented (`/health`)
- [ ] Readiness check endpoint implemented (`/ready`)
- [ ] Application logs configuration (non-sensitive parts)
- [ ] Error messages are clear and actionable

### Infrastructure Readiness
- [ ] Target namespace exists
- [ ] ServiceAccount exists (if needed)
- [ ] RBAC configured (if needed)
- [ ] NetworkPolicies configured (if needed)
- [ ] ResourceQuotas won't block deployment

### Testing
- [ ] Tested in lower environment (staging/dev)
- [ ] Integration tests passed
- [ ] Load tests passed (if applicable)
- [ ] Security scans passed
- [ ] Configuration validated with `kubectl apply --dry-run=server`

### Documentation
- [ ] Deployment procedure documented
- [ ] Rollback procedure documented
- [ ] Configuration changes documented
- [ ] Team notified of deployment

## Deployment

### Execute Deployment
- [ ] Use appropriate deployment method:
  - [ ] `kubectl apply -k overlays/<env>` (Kustomize)
  - [ ] `helm upgrade --install <chart>` (Helm)
  - [ ] CI/CD pipeline triggered
- [ ] Watch deployment progress: `kubectl rollout status`
- [ ] Monitor pod creation: `kubectl get pods -w`
- [ ] Check for errors: `kubectl get events`

### Verification During Deployment
- [ ] Pods are being created
- [ ] Pods pass readiness checks
- [ ] Old pods terminate gracefully
- [ ] No error events in namespace
- [ ] ConfigMaps/Secrets mounted correctly

## Post-Deployment

### Health Verification
- [ ] All pods are Running and Ready
- [ ] Health checks passing: `curl /health`
- [ ] Readiness checks passing: `curl /ready`
- [ ] No crashloops or restarts
- [ ] Logs show successful startup

### Functional Verification
- [ ] Application responds to requests
- [ ] Can connect to dependencies (database, Redis, etc.)
- [ ] API endpoints working
- [ ] Critical user flows tested
- [ ] No errors in logs

### Configuration Verification
- [ ] Environment variables loaded correctly
- [ ] ConfigMaps mounted correctly
- [ ] Secrets available to application
- [ ] Configuration logged on startup (non-sensitive)

### Integration Verification
- [ ] Downstream services reachable
- [ ] Upstream services can reach this service
- [ ] Service discovery working
- [ ] Network policies not blocking traffic

### Monitoring Verification
- [ ] Metrics being collected
- [ ] Logs being shipped to centralized logging
- [ ] Dashboards showing data
- [ ] Alerts configured and working

### Performance Verification
- [ ] Response times acceptable
- [ ] Resource usage (CPU, memory) normal
- [ ] No resource throttling
- [ ] No memory leaks detected

## If Something Goes Wrong

### Quick Checks
- [ ] Check pod status: `kubectl get pods`
- [ ] Check logs: `kubectl logs <pod>`
- [ ] Check events: `kubectl get events --sort-by='.lastTimestamp'`
- [ ] Check previous logs: `kubectl logs <pod> --previous`
- [ ] Check describe: `kubectl describe pod <pod>`

### Common Issues
- [ ] Missing ConfigMap → Apply correct overlay
- [ ] Missing Secret → Create secret
- [ ] Wrong configuration → Update and restart pods
- [ ] Resource limits → Increase limits
- [ ] Health check failing → Check application logs

### Rollback Decision
If issues can't be resolved quickly:
- [ ] Notify team of rollback
- [ ] Execute rollback: `kubectl rollout undo deployment/<name>`
- [ ] Verify rollback successful
- [ ] Document what went wrong
- [ ] Schedule post-mortem

## Rollback Procedure

### Execute Rollback
- [ ] Identify previous working version
- [ ] Execute rollback command
- [ ] Watch rollback progress
- [ ] Verify pods are running old version

### Verify Rollback
- [ ] Application functioning correctly
- [ ] All health checks passing
- [ ] No errors in logs
- [ ] Users can use the application

### Document Rollback
- [ ] Reason for rollback
- [ ] Timeline of events
- [ ] Root cause (if known)
- [ ] Action items to prevent recurrence

## Post-Deployment Follow-Up

### Monitoring (First Hour)
- [ ] Monitor error rates
- [ ] Monitor response times
- [ ] Monitor resource usage
- [ ] Monitor dependency health
- [ ] Check for alerts

### Monitoring (First Day)
- [ ] Review logs for errors
- [ ] Check metrics trends
- [ ] Verify no performance degradation
- [ ] Collect user feedback
- [ ] Review incident reports

### Documentation
- [ ] Update deployment documentation
- [ ] Document any issues encountered
- [ ] Update runbooks if needed
- [ ] Share learnings with team

## Configuration-Specific Checklist

### For New Configuration Keys
- [ ] Added to base ConfigMap
- [ ] Added to all environment overlays
- [ ] Application updated to use new key
- [ ] Default value provided (if applicable)
- [ ] Documentation updated

### For New Secrets
- [ ] Created in all environments
- [ ] Not committed to Git
- [ ] Rotation schedule defined
- [ ] Access documented
- [ ] Used via Secret reference (not hardcoded)

### For Configuration Changes
- [ ] Tested in development
- [ ] Tested in staging
- [ ] Reviewed by team
- [ ] Backwards compatible (if possible)
- [ ] Migration plan if breaking change

## Environment-Specific Notes

### Staging
- [ ] Can use test data
- [ ] Can use mock services
- [ ] Can have verbose logging
- [ ] Can have lower resource limits
- [ ] Should be as close to production as possible

### Production
- [ ] Use real data sources
- [ ] Use production services
- [ ] Use appropriate log levels
- [ ] Use production-grade resources
- [ ] Follow all security procedures

## Sign-Off

**Deployer:** _________________________  
**Date/Time:** _________________________  
**Environment:** _________________________  
**Version Deployed:** _________________________  
**Rollback Plan:** _________________________  

**Reviewer:** _________________________  
**Approval:** [ ] Approved [ ] Rejected  

---

## Quick Reference Commands

```bash
# Preview deployment
kubectl kustomize overlays/<env>

# Deploy
kubectl apply -k overlays/<env>

# Watch deployment
kubectl rollout status deployment/<name> -n <namespace>

# Check pods
kubectl get pods -n <namespace> -l app=<name>

# Check logs
kubectl logs -n <namespace> -l app=<name>

# Check config
kubectl get configmap <name> -n <namespace> -o yaml

# Check secrets (keys only)
kubectl get secret <name> -n <namespace> -o jsonpath='{.data}' | jq 'keys'

# Rollback
kubectl rollout undo deployment/<name> -n <namespace>

# Restart pods
kubectl rollout restart deployment/<name> -n <namespace>
```

## Notes

_Use this space for deployment-specific notes:_

---

**Last Updated:** [Date]  
**Version:** 1.0
