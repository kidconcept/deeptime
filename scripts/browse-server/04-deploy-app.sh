#!/bin/bash
# 04-deploy-app.sh
# Deploys the Leaflet viewer application to the browse-server VM

set -e

source "$(dirname "$0")/../utils.sh"

APP_DIR="/var/www/leaflet-viewer"
LOCAL_APP_PATH="browse-server"

echo "🚀 Deploying Leaflet application to browse-server..."

# Stop running process, create directory, set permissions
gcloud compute ssh "$VM_NAME" --zone "$ZONE" --command="
  set -e
  echo '--- Preparing remote directory ---'
  sudo pm2 stop server || echo 'PM2 process not running, continuing...'
  sudo mkdir -p $APP_DIR
  sudo chown -R \$USER:\$USER $APP_DIR
"

# Copy application files
echo "--- Copying application files ---"
gcloud compute scp --recurse "$LOCAL_APP_PATH/" "$VM_NAME:$APP_DIR" --zone "$ZONE"

# Install dependencies and restart server
gcloud compute ssh "$VM_NAME" --zone "$ZONE" --command="
  set -e
  cd $APP_DIR
  echo '--- Installing npm dependencies ---'
  npm install

  echo '--- Starting application with PM2 ---'
  pm2 start server.js --name leaflet-viewer -- --production
  
  echo '--- Configuring PM2 to start on boot ---'
  sudo env PATH=\$PATH:/usr/bin pm2 startup systemd -u \$USER --hp /home/\$USER
  pm2 save

  echo '--- Deployment complete! ---'
"

echo "✅ Application deployed and running at http://$VM_STATIC_IP:$PORT"
