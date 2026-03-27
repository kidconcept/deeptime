#!/bin/bash
# deploy-browse-server.sh
# Master script to deploy the entire Browse Server feature.

set -e

# --- Configuration ---
export VM_NAME="browse-server"
export ZONE="us-central1-a"
export VM_STATIC_IP="34.61.65.156" # Replace with your reserved IP
export PORT="8081"
export FIREWALL_RULE="allow-browse-server"

# --- Utility Functions ---
source "$(dirname "$0")/utils.sh"

# --- Deployment Steps ---
echo "🚀 Starting full deployment of Browse Server..."

# Step 0: Start the VM if it's not running
if ! is_vm_running; then
  echo "🔵 VM is not running. Starting it now..."
  gcloud compute instances start "$VM_NAME" --zone "$ZONE"
  echo "⏳ Waiting for VM to boot..."
  sleep 30 # Wait for boot and services
else
  echo "🟢 VM is already running."
fi

# Execute deployment scripts in order
SCRIPT_DIR="$(dirname "$0")/browse-server"
for script in $(ls -1 "$SCRIPT_DIR" | sort); do
  echo ""
  echo "--- Executing $script ---"
  bash "$SCRIPT_DIR/$script"
done

echo ""
echo "✨ All deployment steps completed successfully!"
echo "✅ Browse Server is running at http://$VM_STATIC_IP:$PORT"
