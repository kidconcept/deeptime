#!/bin/bash
# scripts/utils.sh
# Shared utility functions for deployment scripts

# --- VM Status ---
is_vm_running() {
  gcloud compute instances describe "$VM_NAME" --zone "$ZONE" --format='get(status)' | grep -q "RUNNING"
}
