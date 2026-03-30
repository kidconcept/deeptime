#!/bin/bash
# deploy.sh
# Deploy application code updates to existing browse server
# Only runs Phase 3 (assumes VM and environment already set up)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
CONFIG_FILE="${1:-$SCRIPT_DIR/.deploy-config}"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Error: Configuration file not found: $CONFIG_FILE"
  echo ""
  echo "📝 Create one by copying the example:"
  echo "   cp .deploy-config.example .deploy-config"
  echo "   # Edit .deploy-config with your settings"
  echo ""
  exit 1
fi

echo "📋 Loading configuration from: $CONFIG_FILE"
set -a
source "$CONFIG_FILE"
set +a
echo ""

echo "🚀 Deploying Browse Server Updates"
echo "===================================="
echo "VM: $VM_NAME"
echo "Zone: $ZONE"
echo ""

# Ensure VM is running
echo "🔍 Checking VM status..."
VM_STATUS=$(gcloud compute instances describe "$VM_NAME" --zone="$ZONE" --format="get(status)" 2>/dev/null || echo "NOT_FOUND")

if [ "$VM_STATUS" = "NOT_FOUND" ]; then
  echo "❌ Error: VM '$VM_NAME' not found"
  echo "   Run ./provision.sh to create it first"
  exit 1
elif [ "$VM_STATUS" = "TERMINATED" ]; then
  echo "🔵 VM is stopped. Starting it..."
  gcloud compute instances start "$VM_NAME" --zone="$ZONE"
  echo "⏳ Waiting for VM to boot..."
  sleep 30
elif [ "$VM_STATUS" = "RUNNING" ]; then
  echo "✅ VM is running"
else
  echo "⚠️  VM status: $VM_STATUS"
fi

echo ""

# Deploy application (Phase 3 only)
bash "$SCRIPT_DIR/_lib/deploy-app.sh"

echo ""
echo "✅ Deployment Complete!"
echo ""
echo "🌐 Browse Server: http://$VM_STATIC_IP:$PORT"
echo "📊 View logs: ./logs.sh"
echo ""
