#!/bin/bash
# Test all code examples to ensure they work

set -e

echo "🧪 Testing code examples..."

# Track results
PASSED=0
FAILED=0
SKIPPED=0

# Test each chapter
for chapter_dir in examples/chapter-*; do
    chapter=$(basename "$chapter_dir")
    
    if [ -f "$chapter_dir/test.sh" ]; then
        echo ""
        echo "Testing $chapter..."
        
        if bash "$chapter_dir/test.sh"; then
            echo "✓ $chapter passed"
            ((PASSED++))
        else
            echo "✗ $chapter failed"
            ((FAILED++))
        fi
    else
        echo "○ $chapter - no tests found"
        ((SKIPPED++))
    fi
done

# Summary
echo ""
echo "================================"
echo "Test Summary:"
echo "  Passed:  $PASSED"
echo "  Failed:  $FAILED"
echo "  Skipped: $SKIPPED"
echo "================================"

if [ $FAILED -eq 0 ]; then
    echo "✅ All tests passed!"
    exit 0
else
    echo "❌ Some tests failed"
    exit 1
fi
