#!/bin/bash
# provision.sh
# Full provisioning of browse server from scratch
# Runs all three phases: Infrastructure, Environment, Application

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
source "$CONFIG_FILE"
echo ""

echo "🎯 Browse Server Provisioning"
echo "=============================="
echo "VM: $VM_NAME"
echo "Zone: $ZONE"
echo "IP: $VM_STATIC_IP"
echo "Port: $PORT"
echo ""
read -p "Continue with provisioning? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
  echo "Aborted."
  exit 0
fi
echo ""

# Phase 1: Create Infrastructure
bash "$SCRIPT_DIR/_lib/create-vm.sh"

# Phase 2: Setup Environment
bash "$SCRIPT_DIR/_lib/setup-environment.sh"

# Phase 3: Deploy Application
bash "$SCRIPT_DIR/_lib/deploy-app.sh"

echo ""
echo "🎉 Provisioning Complete!"
echo "=========================="
echo ""
echo "✅ Browse Server is ready at: http://$VM_STATIC_IP:$PORT"
echo ""
echo "Useful commands:"
echo "  ./deploy.sh  - Deploy code updates"
echo "  ./logs.sh    - View application logs"
echo "  ./stop.sh    - Stop VM to save costs"
echo "  ./ssh.sh     - SSH into VM"
echo ""
