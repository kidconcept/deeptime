#!/bin/bash
# stop-browse-server.sh
# Stops the browse-server VM to prevent billing.

set -e

# --- Configuration ---
export VM_NAME="browse-server"
export ZONE="us-central1-a"

# --- Utility Functions ---
source "$(dirname "$0")/utils.sh"

# --- Main ---
echo "🛑 Stopping Browse Server VM..."

if is_vm_running; then
  gcloud compute instances stop "$VM_NAME" --zone "$ZONE"
  echo "✅ VM instance '$VM_NAME' stopped."
else
  echo "⚪ VM is already stopped."
fi
