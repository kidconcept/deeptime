#!/bin/bash
# start.sh
# Start a stopped browse server VM

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
CONFIG_FILE="${1:-$SCRIPT_DIR/.deploy-config}"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Error: Configuration file not found: $CONFIG_FILE"
  exit 1
fi

source "$CONFIG_FILE"

echo "🔵 Starting Browse Server VM"
echo "=============================="
echo "VM: $VM_NAME"
echo "Zone: $ZONE"
echo ""

VM_STATUS=$(gcloud compute instances describe "$VM_NAME" --zone="$ZONE" --format="get(status)" 2>/dev/null || echo "NOT_FOUND")

if [ "$VM_STATUS" = "NOT_FOUND" ]; then
  echo "❌ Error: VM '$VM_NAME' not found"
  exit 1
elif [ "$VM_STATUS" = "RUNNING" ]; then
  echo "✅ VM is already running"
  echo "🌐 Browse Server: http://$VM_STATIC_IP:$PORT"
  exit 0
fi

echo "▶️  Starting VM..."
gcloud compute instances start "$VM_NAME" --zone="$ZONE"

echo "⏳ Waiting for VM to boot..."
sleep 30

echo ""
echo "✅ VM Started"
echo "🌐 Browse Server: http://$VM_STATIC_IP:$PORT"
echo ""
