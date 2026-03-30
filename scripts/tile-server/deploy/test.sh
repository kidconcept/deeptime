#!/bin/bash
# Test TiTiler deployment

set -e

# Get script directory and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Load environment variables from repo root
source "$REPO_ROOT/.env"

echo "========================================="
echo "Testing TiTiler Deployment"
echo "========================================="
echo "URL: $TITILER_URL"
echo "COG: $COG_GCS_URI"
echo ""

# Test 1: Info endpoint
echo "Test 1: COG Info endpoint..."
RESPONSE=$(curl -sf "${TITILER_URL}/cog/info?url=${COG_GCS_URI}")
if echo "$RESPONSE" | grep -q "bounds"; then
  echo "✅ Info endpoint working"
  echo "   Bounds: $(echo $RESPONSE | grep -o '"bounds":\[[^]]*\]')"
else
  echo "❌ Info endpoint failed"
  echo "   Response: $RESPONSE"
  exit 1
fi

echo ""

# Test 2: Preview endpoint
echo "Test 2: Preview endpoint..."
if curl -sf "${TITILER_URL}/cog/preview.png?url=${COG_GCS_URI}&max_size=512" -o /tmp/test-preview.png; then
  SIZE=$(wc -c < /tmp/test-preview.png)
  if [ $SIZE -gt 1000 ]; then
    echo "✅ Preview endpoint working (${SIZE} bytes)"
    rm /tmp/test-preview.png
  else
    echo "❌ Preview too small (${SIZE} bytes)"
    exit 1
  fi
else
  echo "❌ Preview endpoint failed"
  exit 1
fi

echo ""
echo "========================================="
echo "All Tests Passed!"
echo "========================================="
