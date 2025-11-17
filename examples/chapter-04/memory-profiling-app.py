#!/usr/bin/env python3
"""
Sample application with memory profiling
Chapter 4: The Resource Crunch
"""

from flask import Flask, jsonify
import tracemalloc
import os
from functools import lru_cache

app = Flask(__name__)
tracemalloc.start()

@lru_cache(maxsize=100)
def load_template(template_name):
    return f"Template content for {template_name}" * 100

@app.route('/health')
def health():
    return jsonify({'status': 'healthy'}), 200

@app.route('/ready')
def ready():
    current, peak = tracemalloc.get_traced_memory()
    current_mb = current / 1024 / 1024
    if current_mb > 400:
        return jsonify({'status': 'not ready', 'memory_mb': current_mb}), 503
    return jsonify({'status': 'ready', 'memory_mb': current_mb}), 200

@app.route('/debug/memory')
def memory_snapshot():
    snapshot = tracemalloc.take_snapshot()
    top_stats = snapshot.statistics('lineno')
    current, peak = tracemalloc.get_traced_memory()
    
    memory_info = []
    for stat in top_stats[:10]:
        memory_info.append({
            'file': str(stat.traceback),
            'size_mb': round(stat.size / 1024 / 1024, 2)
        })
    
    return jsonify({
        'current_mb': round(current / 1024 / 1024, 2),
        'peak_mb': round(peak / 1024 / 1024, 2),
        'top_allocations': memory_info
    })

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.getenv('PORT', '8080')))
