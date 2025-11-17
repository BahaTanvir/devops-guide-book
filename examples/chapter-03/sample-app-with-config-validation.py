#!/usr/bin/env python3
"""
Sample application with proper configuration validation
Chapter 3: "It Works on My Machine"

This demonstrates how to validate configuration on startup
and fail fast if something is missing.
"""

from flask import Flask, jsonify
import os
import sys
import logging

app = Flask(__name__)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

def validate_config():
    """
    Validate required configuration on startup.
    Fail fast if any required config is missing.
    """
    logger.info("Validating configuration...")
    
    required_vars = {
        'SMTP_HOST': os.getenv('SMTP_HOST'),
        'SMTP_PORT': os.getenv('SMTP_PORT'),
        'SMTP_USER': os.getenv('SMTP_USER'),
        'SMTP_PASS': os.getenv('SMTP_PASS'),
        'PUSH_API_KEY': os.getenv('PUSH_API_KEY'),
        'REDIS_URL': os.getenv('REDIS_URL'),
        'USER_SERVICE_URL': os.getenv('USER_SERVICE_URL'),
    }
    
    # Check for missing variables
    missing = [k for k, v in required_vars.items() if not v]
    
    if missing:
        logger.error(f"❌ Missing required configuration: {missing}")
        logger.error("Application cannot start without required configuration")
        sys.exit(1)
    
    # Log configuration (not sensitive values!)
    logger.info("✅ Configuration validated successfully")
    logger.info(f"  SMTP Host: {required_vars['SMTP_HOST']}")
    logger.info(f"  SMTP Port: {required_vars['SMTP_PORT']}")
    logger.info(f"  SMTP User: {required_vars['SMTP_USER']}")
    logger.info(f"  Redis URL: {required_vars['REDIS_URL']}")
    logger.info(f"  User Service URL: {required_vars['USER_SERVICE_URL']}")
    # Don't log passwords or API keys!
    
    return required_vars

# Validate on startup
try:
    config = validate_config()
except Exception as e:
    logger.error(f"Configuration validation failed: {e}")
    sys.exit(1)

@app.route('/health')
def health():
    """Basic health check"""
    return jsonify({'status': 'healthy'}), 200

@app.route('/ready')
def ready():
    """
    Readiness check - verifies configuration is loaded
    In a real app, also check database connectivity, etc.
    """
    try:
        # Verify critical config is still accessible
        if not os.getenv('SMTP_HOST') or not os.getenv('REDIS_URL'):
            return jsonify({
                'status': 'not ready',
                'reason': 'Configuration missing'
            }), 503
        
        return jsonify({
            'status': 'ready',
            'config_loaded': True
        }), 200
    except Exception as e:
        return jsonify({
            'status': 'not ready',
            'error': str(e)
        }), 503

@app.route('/api/send-notification', methods=['POST'])
def send_notification():
    """
    Example endpoint that uses configuration
    """
    logger.info(f"Sending notification via SMTP: {config['SMTP_HOST']}")
    
    # In a real app, you would:
    # 1. Connect to SMTP server using config
    # 2. Send email
    # 3. Return result
    
    return jsonify({
        'status': 'sent',
        'smtp_host': config['SMTP_HOST']  # For demo only
    }), 200

@app.route('/api/config-info')
def config_info():
    """
    Return non-sensitive configuration info
    Useful for debugging environment issues
    """
    return jsonify({
        'smtp_configured': bool(os.getenv('SMTP_HOST')),
        'redis_configured': bool(os.getenv('REDIS_URL')),
        'push_configured': bool(os.getenv('PUSH_API_KEY')),
        'log_level': os.getenv('LOG_LEVEL', 'INFO'),
        'environment': os.getenv('ENVIRONMENT', 'unknown')
    }), 200

if __name__ == '__main__':
    logger.info("Starting Notification Service...")
    logger.info(f"Port: {os.getenv('PORT', '8080')}")
    logger.info(f"Log Level: {os.getenv('LOG_LEVEL', 'INFO')}")
    
    app.run(
        host='0.0.0.0',
        port=int(os.getenv('PORT', '8080')),
        debug=False
    )
