#!/bin/bash
# Test script to verify array value handling

set -e

echo "Testing array value formatting..."

# Source the format_value function from deploy.sh
source <(sed -n '/^format_value()/,/^}/p' ../deploy.sh)

# Test cases
echo ""
echo "Test 1: Array with escaped quotes (from YAML/JSON pipeline)"
result=$(format_value '[\"dc1\"]')
expected='["dc1"]'
if [ "$result" = "$expected" ]; then
    echo "✅ PASS: $result"
else
    echo "❌ FAIL: Expected '$expected', got '$result'"
    exit 1
fi

echo ""
echo "Test 2: Array with unescaped quotes (direct)"
result=$(format_value '["dc1"]')
expected='["dc1"]'
if [ "$result" = "$expected" ]; then
    echo "✅ PASS: $result"
else
    echo "❌ FAIL: Expected '$expected', got '$result'"
    exit 1
fi

echo ""
echo "Test 3: Multi-element array"
result=$(format_value '[\"dc1\", \"dc2\", \"dc3\"]')
expected='["dc1", "dc2", "dc3"]'
if [ "$result" = "$expected" ]; then
    echo "✅ PASS: $result"
else
    echo "❌ FAIL: Expected '$expected', got '$result'"
    exit 1
fi

echo ""
echo "Test 4: Number"
result=$(format_value '123')
expected='123'
if [ "$result" = "$expected" ]; then
    echo "✅ PASS: $result"
else
    echo "❌ FAIL: Expected '$expected', got '$result'"
    exit 1
fi

echo ""
echo "Test 5: Boolean"
result=$(format_value 'true')
expected='true'
if [ "$result" = "$expected" ]; then
    echo "✅ PASS: $result"
else
    echo "❌ FAIL: Expected '$expected', got '$result'"
    exit 1
fi

echo ""
echo "Test 6: String"
result=$(format_value 'hello-world')
expected='"hello-world"'
if [ "$result" = "$expected" ]; then
    echo "✅ PASS: $result"
else
    echo "❌ FAIL: Expected '$expected', got '$result'"
    exit 1
fi

echo ""
echo "Test 7: Empty value"
result=$(format_value '')
expected='""'
if [ "$result" = "$expected" ]; then
    echo "✅ PASS: $result"
else
    echo "❌ FAIL: Expected '$expected', got '$result'"
    exit 1
fi

echo ""
echo "✅ All tests passed!"
