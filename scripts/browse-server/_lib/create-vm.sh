#!/bin/bash
# _lib/create-vm.sh
# Phase 1: Creates VM infrastructure (VM instance, static IP, firewall)
# This script is called by provision.sh and should not be run directly

set -e

# Verify required variables are set
: "${VM_NAME:?VM_NAME not set}"
: "${ZONE:?ZONE not set}"
: "${VM_STATIC_IP:?VM_STATIC_IP not set}"
: "${MACHINE_TYPE:?MACHINE_TYPE not set}"
: "${DISK_SIZE:?DISK_SIZE not set}"
: "${IMAGE_FAMILY:?IMAGE_FAMILY not set}"
: "${IMAGE_PROJECT:?IMAGE_PROJECT not set}"
: "${NETWORK_TAG:?NETWORK_TAG not set}"
: "${FIREWALL_RULE:?FIREWALL_RULE not set}"
: "${PORT:?PORT not set}"

echo "🏗️  Phase 1: Creating VM Infrastructure"
echo "========================================"

# Check if VM already exists
if gcloud compute instances describe "$VM_NAME" --zone="$ZONE" &>/dev/null; then
  echo "✅ VM '$VM_NAME' already exists"
else
  echo "📦 Creating VM instance '$VM_NAME'..."
  
  # Reserve static IP if it doesn't exist
  if ! gcloud compute addresses describe "${VM_NAME}-ip" --region="$(echo $ZONE | sed 's/-[a-z]$//')" &>/dev/null; then
    echo "🔢 Reserving static IP address..."
    gcloud compute addresses create "${VM_NAME}-ip" \
      --region="$(echo $ZONE | sed 's/-[a-z]$//')"
  fi
  
  # Create VM instance
  gcloud compute instances create "$VM_NAME" \
    --zone="$ZONE" \
    --machine-type="$MACHINE_TYPE" \
    --image-family="$IMAGE_FAMILY" \
    --image-project="$IMAGE_PROJECT" \
    --boot-disk-size="$DISK_SIZE" \
    --boot-disk-type=pd-standard \
    --address="$VM_STATIC_IP" \
    --tags="$NETWORK_TAG" \
    --metadata=enable-oslogin=TRUE
    
  echo "✅ VM created successfully"
  echo "⏳ Waiting for VM to boot..."
  sleep 30
fi

# Create firewall rule if it doesn't exist
if gcloud compute firewall-rules describe "$FIREWALL_RULE" &>/dev/null; then
  echo "✅ Firewall rule '$FIREWALL_RULE' already exists"
else
  echo "🔥 Creating firewall rule for port $PORT..."
  gcloud compute firewall-rules create "$FIREWALL_RULE" \
    --allow=tcp:"$PORT" \
    --target-tags="$NETWORK_TAG" \
    --description="Allow ingress on port $PORT for browse server"
  echo "✅ Firewall rule created"
fi

echo ""
echo "✅ Phase 1 Complete: Infrastructure Ready"
echo "   VM: $VM_NAME"
echo "   IP: $VM_STATIC_IP"
echo "   Port: $PORT"
echo ""
