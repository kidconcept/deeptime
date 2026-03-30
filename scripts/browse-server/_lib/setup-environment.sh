#!/bin/bash
# _lib/setup-environment.sh
# Phase 2: Sets up Node.js and PM2 on the VM
# This script is called by provision.sh and should not be run directly

set -e

# Verify required variables are set
: "${VM_NAME:?VM_NAME not set}"
: "${ZONE:?ZONE not set}"
: "${APP_DIR:?APP_DIR not set}"

echo "🔧 Phase 2: Setting Up Environment"
echo "==================================="

echo "📦 Installing Node.js v20 and PM2..."

gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="
  set -e
  
  # Check if Node.js is already installed
  if command -v node &>/dev/null; then
    echo '✅ Node.js already installed:' \$(node -v)
  else
    echo '📥 Installing Node.js v20...'
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt-get install -y nodejs
    echo '✅ Node.js installed:' \$(node -v)
  fi
  
  # Check if PM2 is already installed
  if command -v pm2 &>/dev/null; then
    echo '✅ PM2 already installed:' \$(pm2 -v)
  else
    echo '📥 Installing PM2 process manager...'
    sudo npm install -g pm2
    echo '✅ PM2 installed:' \$(pm2 -v)
  fi
  
  # Create application directory
  echo '📁 Creating application directory...'
  sudo mkdir -p $APP_DIR
  sudo chown -R \$USER:\$USER $APP_DIR
  echo '✅ Application directory created: $APP_DIR'
"

echo ""
echo "✅ Phase 2 Complete: Environment Ready"
echo "   Node.js and PM2 installed"
echo "   Application directory: $APP_DIR"
echo ""
