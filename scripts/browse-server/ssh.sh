#!/bin/bash
# ssh.sh
# SSH into the browse server VM

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
CONFIG_FILE="${1:-$SCRIPT_DIR/.deploy-config}"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Error: Configuration file not found: $CONFIG_FILE"
  exit 1
fi

source "$CONFIG_FILE"

echo "🔐 Connecting to Browse Server"
echo "==============================="
echo "VM: $VM_NAME"
echo "Zone: $ZONE"
echo ""

gcloud compute ssh "$VM_NAME" --zone="$ZONE"
