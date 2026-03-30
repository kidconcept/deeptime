#!/bin/bash
# stop.sh
# Stop the browse server VM to save costs

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
CONFIG_FILE="${1:-$SCRIPT_DIR/.deploy-config}"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Error: Configuration file not found: $CONFIG_FILE"
  exit 1
fi

source "$CONFIG_FILE"

echo "⏸️  Stopping Browse Server VM"
echo "=============================="
echo "VM: $VM_NAME"
echo "Zone: $ZONE"
echo ""

VM_STATUS=$(gcloud compute instances describe "$VM_NAME" --zone="$ZONE" --format="get(status)" 2>/dev/null || echo "NOT_FOUND")

if [ "$VM_STATUS" = "NOT_FOUND" ]; then
  echo "❌ Error: VM '$VM_NAME' not found"
  exit 1
elif [ "$VM_STATUS" = "TERMINATED" ]; then
  echo "✅ VM is already stopped"
  exit 0
fi

echo "⏹️  Stopping VM..."
gcloud compute instances stop "$VM_NAME" --zone="$ZONE"

echo ""
echo "✅ VM Stopped"
echo ""
echo "💰 Cost savings:"
echo "   • Compute charges: Stopped (saving ~\$6/month)"
echo "   • Static IP: Still reserved (~\$3/month)"
echo "   • Disk storage: Still allocated (~\$1/month)"
echo ""
echo "▶️  Restart with: ./start.sh"
echo ""
