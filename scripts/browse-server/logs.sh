#!/bin/bash
# logs.sh
# View PM2 application logs from the browse server

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load configuration
CONFIG_FILE="${1:-$SCRIPT_DIR/.deploy-config}"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ Error: Configuration file not found: $CONFIG_FILE"
  exit 1
fi

source "$CONFIG_FILE"

echo "📊 Browse Server Logs"
echo "======================"
echo "VM: $VM_NAME"
echo "Zone: $ZONE"
echo ""
echo "Press Ctrl+C to exit"
echo ""

# Stream PM2 logs
gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="pm2 logs leaflet-viewer --lines 50"
