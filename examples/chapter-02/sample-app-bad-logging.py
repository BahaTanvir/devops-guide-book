#!/usr/bin/env python3
"""
Sample application with BAD logging practices
Chapter 2: The Mystery of the Disappearing Logs

This shows what NOT to do.
"""

from flask import Flask, request, jsonify
import random

app = Flask(__name__)

@app.route('/api/users/<user_id>')
def get_user(user_id):
    """Get user by ID - with bad logging"""
    try:
        # Simulate getting user from database
        if random.random() < 0.1:  # 10% failure rate
            raise Exception("Database error")
        
        user = {
            'id': user_id,
            'name': 'John Doe',
            'email': 'john@example.com'
        }
        
        # Bad logging - no structure, no context
        print(f"Got user {user_id}")
        return jsonify(user)
    
    except Exception as e:
        # Bad error logging - generic, no context
        print(f"Error: {e}")
        return {"error": "Internal server error"}, 500

@app.route('/api/orders', methods=['POST'])
def create_order(order_id):
    """Create order - with bad logging"""
    data = request.json
    
    # Bad: Logging sensitive data
    print(f"Creating order: {data}")  # Might contain credit card!
    
    return {"order_id": "12345"}, 201

@app.route('/health')
def health():
    return {"status": "healthy"}, 200

if __name__ == '__main__':
    # No log configuration
    app.run(host='0.0.0.0', port=8080)
