#!/bin/bash
# 03-setup-node.sh
# Installs Node.js and PM2 on the browse-server VM

set -e

source "$(dirname "$0")/../utils.sh"

echo "📦 Installing Node.js and PM2 on browse-server..."

gcloud compute ssh "$VM_NAME" --zone "$ZONE" --command="
  set -e
  echo '--- Installing Node.js v20 ---'
  curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
  sudo apt-get install -y nodejs

  echo '--- Installing PM2 process manager ---'
  sudo npm install -g pm2

  echo '--- Node.js and PM2 installation complete ---'
  node -v
  npm -v
  pm2 -v
"
