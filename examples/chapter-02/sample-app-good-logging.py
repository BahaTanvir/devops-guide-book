#!/usr/bin/env python3
"""
Sample application with GOOD logging practices
Chapter 2: The Mystery of the Disappearing Logs

This demonstrates proper structured logging.
"""

from flask import Flask, request, jsonify, g
import logging
import json
import uuid
import time
import traceback
import random
from datetime import datetime

app = Flask(__name__)

# Configure structured logging
logging.basicConfig(
    level=logging.INFO,
    format='%(message)s'  # We'll output JSON, so no need for format
)
logger = logging.getLogger(__name__)

def log_json(level, message, **kwargs):
    """Helper to log structured JSON"""
    log_entry = {
        'timestamp': datetime.utcnow().isoformat() + 'Z',
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
    g.start_time = time.time()
    
    log_json('INFO', 'Request started',
             method=request.method,
             path=request.path,
             remote_addr=request.remote_addr,
             user_agent=request.headers.get('User-Agent', 'unknown'))

@app.after_request
def after_request(response):
    """Log response details"""
    duration_ms = (time.time() - g.get('start_time', time.time())) * 1000
    
    # Determine log level based on status code
    if response.status_code >= 500:
        level = 'ERROR'
    elif response.status_code >= 400:
        level = 'WARN'
    else:
        level = 'INFO'
    
    log_json(level, 'Request completed',
             status_code=response.status_code,
             duration_ms=round(duration_ms, 2))
    
    return response

@app.route('/api/users/<user_id>')
def get_user(user_id):
    """Get user by ID - with good logging"""
    log_json('INFO', 'Fetching user', user_id=user_id)
    
    try:
        # Simulate database call
        if random.random() < 0.1:  # 10% failure rate
            raise ConnectionError("Database connection timeout")
        
        user = {
            'id': user_id,
            'name': 'John Doe',
            'email': 'john@example.com'
        }
        
        log_json('INFO', 'User fetched successfully',
                user_id=user_id,
                found=True)
        
        return jsonify(user)
    
    except ConnectionError as e:
        log_json('ERROR', 'Database connection failed',
                user_id=user_id,
                error=str(e),
                error_type='ConnectionError',
                retry_count=0)
        return {"error": "Service temporarily unavailable"}, 503
    
    except Exception as e:
        log_json('ERROR', 'Unexpected error',
                user_id=user_id,
                error=str(e),
                error_type=type(e).__name__,
                traceback=traceback.format_exc())
        return {"error": "Internal server error"}, 500

@app.route('/api/orders', methods=['POST'])
def create_order():
    """Create order - with good logging (sanitized)"""
    data = request.json
    
    # Sanitize sensitive data before logging
    safe_data = {
        k: '***REDACTED***' if k in ['credit_card', 'password', 'ssn'] else v
        for k, v in data.items()
    }
    
    log_json('INFO', 'Creating order',
            order_data=safe_data,
            item_count=len(data.get('items', [])))
    
    # Simulate order creation
    order_id = str(uuid.uuid4())
    
    log_json('INFO', 'Order created successfully',
            order_id=order_id,
            total_amount=data.get('total', 0))
    
    return {"order_id": order_id}, 201

@app.route('/api/slow')
def slow_endpoint():
    """Simulate slow endpoint for performance tracking"""
    log_json('INFO', 'Processing slow request')
    
    # Simulate slow operation
    time.sleep(2)
    
    log_json('WARN', 'Slow operation completed',
            duration_ms=2000,
            operation='data_processing')
    
    return {"status": "completed"}, 200

@app.route('/health')
def health():
    """Health check endpoint"""
    return {"status": "healthy"}, 200

@app.route('/ready')
def ready():
    """Readiness check endpoint"""
    # In real app, check database connectivity, etc.
    return {"status": "ready"}, 200

@app.errorhandler(404)
def not_found(error):
    """Handle 404 errors"""
    log_json('WARN', 'Resource not found',
            path=request.path,
            method=request.method)
    return {"error": "Not found"}, 404

@app.errorhandler(500)
def internal_error(error):
    """Handle 500 errors"""
    log_json('ERROR', 'Internal server error',
            error=str(error),
            traceback=traceback.format_exc())
    return {"error": "Internal server error"}, 500

if __name__ == '__main__':
    log_json('INFO', 'Application starting',
            port=8080,
            environment='production')
    
    app.run(host='0.0.0.0', port=8080)
