#!/bin/bash
# _lib/deploy-app.sh
# Phase 3: Deploys application code to the VM
# This script is called by both provision.sh and deploy.sh

set -e

# Verify required variables are set
: "${VM_NAME:?VM_NAME not set}"
: "${ZONE:?ZONE not set}"
: "${APP_DIR:?APP_DIR not set}"

echo "🚀 Phase 3: Deploying Application"
echo "=================================="

# Get the absolute path to the browse-server directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_APP_PATH="$SCRIPT_DIR/../../../browse-server"
REPO_ROOT="$SCRIPT_DIR/../../.."

if [ ! -d "$LOCAL_APP_PATH" ]; then
  echo "❌ Error: browse-server directory not found at $LOCAL_APP_PATH"
  exit 1
fi

# Check if .env exists in repo root
if [ ! -f "$REPO_ROOT/.env" ]; then
  echo "⚠️  Warning: .env file not found at $REPO_ROOT/.env"
  echo "   The application will use fallback URLs from code"
fi

echo "📦 Source: $LOCAL_APP_PATH"
echo "📍 Target: $VM_NAME:$APP_DIR"
echo ""

# Copy files to temporary location on VM
echo "📤 Copying application files to VM..."
gcloud compute scp --recurse "$LOCAL_APP_PATH/" "$VM_NAME:/tmp/leaflet-viewer-new" --zone="$ZONE"

# Copy .env file if it exists
if [ -f "$REPO_ROOT/.env" ]; then
  echo "📤 Copying .env file to VM..."
  gcloud compute scp "$REPO_ROOT/.env" "$VM_NAME:/tmp/leaflet-viewer-new/.env" --zone="$ZONE"
fi

echo "✅ Files copied to VM"

# Deploy on the VM
echo "🔄 Deploying application..."
gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="
  set -e
  
  # Stop old PM2 process if running
  echo '⏸️  Stopping old application...'
  pm2 stop leaflet-viewer 2>/dev/null || echo 'No previous process to stop'
  
  # Atomic swap: remove old, move new into place
  echo '🔄 Swapping application code...'
  sudo rm -rf $APP_DIR
  sudo mv /tmp/leaflet-viewer-new $APP_DIR
  sudo chown -R \$USER:\$USER $APP_DIR
  
  # Install dependencies
  echo '📦 Installing dependencies...'
  cd $APP_DIR
  npm install --production --silent
  
  # Start application with PM2
  echo '▶️  Starting application...'
  pm2 start server.js --name leaflet-viewer -- --production 2>/dev/null || pm2 restart leaflet-viewer
  
  # Save PM2 configuration
  pm2 save
  
  # Show status
  echo ''
  echo '✅ Application deployed successfully'
  pm2 list
"

echo ""
echo "✅ Phase 3 Complete: Application Deployed"
echo "   Access at: http://${VM_STATIC_IP:-your-ip}:${PORT:-8081}"
echo ""
