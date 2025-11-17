# Useful Log Queries with LogQL
## Chapter 2: The Mystery of the Disappearing Logs

This document contains common LogQL queries for searching logs in Grafana/Loki.

## Basic Queries

### View all logs from a namespace
```logql
{namespace="production"}
```

### View logs from a specific app
```logql
{app="api-service"}
```

### Combine multiple labels
```logql
{namespace="production", app="api-service"}
```

## Filtering Logs

### Find logs containing "ERROR"
```logql
{namespace="production"} |= "ERROR"
```

### Find logs NOT containing "health"
```logql
{namespace="production"} != "health"
```

### Case-insensitive search
```logql
{namespace="production"} |~ "(?i)error"
```

### Multiple filters
```logql
{namespace="production"} |= "ERROR" |= "database"
```

## JSON Parsing

### Parse JSON logs
```logql
{namespace="production"} | json
```

### Filter by JSON field
```logql
{namespace="production"} | json | level="ERROR"
```

### Filter by nested JSON field
```logql
{namespace="production"} | json | error_type="DatabaseConnectionError"
```

### Numeric comparisons
```logql
{namespace="production"} | json | duration_ms > 1000
```

## Request Tracing

### Find all logs for a specific request ID
```logql
{namespace="production"} | json | request_id="abc-123-def-456"
```

### Find requests for a specific user
```logql
{namespace="production"} | json | user_id="user-789"
```

### Find slow requests (> 1 second)
```logql
{namespace="production"} | json | duration_ms > 1000
```

## Time-Based Queries

### Logs from last 5 minutes
```logql
{namespace="production"} [5m]
```

### Logs from last hour
```logql
{namespace="production"} [1h]
```

### Logs from specific time range
Use Grafana's time picker to set the range

## Aggregations and Metrics

### Count logs per app
```logql
count_over_time({namespace="production"}[5m]) by (app)
```

### Error rate per app
```logql
sum(rate({namespace="production"} |= "ERROR"[5m])) by (app)
```

### Requests per second
```logql
sum(rate({app="api-service"} | json | message="Request completed"[1m]))
```

### Average response time
```logql
avg_over_time(
  {app="api-service"} 
  | json 
  | duration_ms > 0 
  | unwrap duration_ms [5m]
)
```

### 95th percentile response time
```logql
quantile_over_time(0.95,
  {app="api-service"}
  | json
  | unwrap duration_ms [5m]
)
```

## Error Analysis

### Group errors by type
```logql
sum(count_over_time({namespace="production"} | json | level="ERROR"[5m])) by (error_type)
```

### Find errors with stack traces
```logql
{namespace="production"} | json | traceback != ""
```

### Errors in last hour grouped by service
```logql
sum(count_over_time({namespace="production"} |= "ERROR"[1h])) by (service)
```

## Performance Monitoring

### Find all slow database queries
```logql
{app="api-service"} | json | message="Database query completed" | duration_ms > 500
```

### Requests by HTTP method
```logql
sum(rate({app="api-service"} | json | message="Request started"[5m])) by (method)
```

### Status code distribution
```logql
sum(rate({app="api-service"} | json | message="Request completed"[5m])) by (status_code)
```

## Debugging Specific Issues

### Find connection timeout errors
```logql
{namespace="production"} |= "timeout" |= "connection"
```

### Find memory-related errors
```logql
{namespace="production"} |~ "OutOfMemory|OOM|memory"
```

### Find authentication failures
```logql
{app="api-service"} | json | message="Authentication failed" or message="Unauthorized"
```

## Security and Audit

### Find failed login attempts
```logql
{app="auth-service"} | json | message="Login failed"
```

### Find access to sensitive endpoints
```logql
{app="api-service"} | json | path=~"/admin.*"
```

### Find requests from specific IP
```logql
{namespace="production"} | json | remote_addr="192.168.1.100"
```

## Advanced Queries

### Logs not matching a pattern (exclusion)
```logql
{namespace="production"} 
  | json 
  | message != "Health check" 
  | message != "Ready check"
```

### Regex pattern matching
```logql
{namespace="production"} |~ "ERROR|FATAL|CRITICAL"
```

### Extract and display specific fields
```logql
{app="api-service"} 
  | json 
  | line_format "{{.timestamp}} [{{.level}}] {{.message}} (request_id={{.request_id}})"
```

### Rate of change
```logql
rate({app="api-service"} | json | level="ERROR"[5m])
```

### Bytes processed
```logql
sum(bytes_over_time({namespace="production"}[1h]))
```

## Alert-Worthy Queries

### High error rate
```logql
sum(rate({namespace="production"} |= "ERROR"[5m])) by (app) > 10
```

### No logs (service might be down)
```logql
sum(count_over_time({app="api-service"}[5m])) == 0
```

### Specific error threshold
```logql
count_over_time({app="api-service"} |= "DatabaseConnectionError"[5m]) > 5
```

### High latency
```logql
quantile_over_time(0.95, 
  {app="api-service"} 
  | json 
  | unwrap duration_ms [5m]
) > 2000
```

## Tips for Effective Queries

1. **Start broad, then narrow**: Begin with namespace/app, then add filters
2. **Use JSON parsing**: Structured logs are much easier to query
3. **Add context to logs**: More fields = more powerful queries
4. **Use request IDs**: Essential for tracing across services
5. **Test queries**: Validate queries return expected results
6. **Create dashboards**: Save useful queries as panels
7. **Set up alerts**: Proactively catch issues

## Query Performance Tips

- Limit time range when possible
- Use specific label selectors
- Avoid regex when simple string matching works
- Use line filters before JSON parsing: `|= "ERROR" | json` is faster than `| json | level="ERROR"`
- Sample high-volume logs: `sum(rate({app="api-service"}[5m])) / 100` for 1% sample
