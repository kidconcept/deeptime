#!/bin/bash
# _lib/deploy-app.sh
# Phase 3: Deploys application from Git commit SHA on the VM
# Called by provision.sh and deploy.sh

set -euo pipefail

# Verify required variables are set
: "${VM_NAME:?VM_NAME not set}"
: "${ZONE:?ZONE not set}"
: "${APP_DIR:?APP_DIR not set}"

echo "Phase 3: Deploying Application (Git SHA)"
echo "========================================"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Deploy target ref. Examples:
# DEPLOY_REF=HEAD ./deploy.sh
# DEPLOY_REF=main ./deploy.sh
# DEPLOY_REF=a1b2c3d4 ./deploy.sh
DEPLOY_REF="${DEPLOY_REF:-HEAD}"

# Resolve commit SHA from local repo
DEPLOY_SHA="$(git -C "$REPO_ROOT" rev-parse "$DEPLOY_REF")"
REPO_URL="$(git -C "$REPO_ROOT" config --get remote.origin.url)"

if [ -z "${REPO_URL:-}" ]; then
  echo "Error: could not determine git remote.origin.url"
  exit 1
fi

echo "Repo: $REPO_URL"
echo "Ref:  $DEPLOY_REF"
echo "SHA:  $DEPLOY_SHA"
echo "VM:   $VM_NAME ($ZONE)"
echo ""

# Ensure .env exists
if [ ! -f "$REPO_ROOT/.env" ]; then
  echo "Warning: .env not found at $REPO_ROOT/.env"
  echo "Continuing without .env copy"
else
  echo "Copying .env to VM..."
  gcloud compute scp "$REPO_ROOT/.env" "$VM_NAME:/tmp/deeptime.env" --zone="$ZONE"
fi

echo "Deploying on VM..."
gcloud compute ssh "$VM_NAME" --zone="$ZONE" --command="
  set -euo pipefail

  APP_DIR='$APP_DIR'
  REPO_URL='$REPO_URL'
  DEPLOY_SHA='$DEPLOY_SHA'

  # Clone once, then keep updating in place
  if [ ! -d \"\$APP_DIR/.git\" ]; then
    echo 'Cloning repository...'
    sudo mkdir -p \"\$APP_DIR\"
    sudo chown -R \$USER:\$USER \"\$APP_DIR\"
    git clone \"\$REPO_URL\" \"\$APP_DIR\"
  fi

  cd \"\$APP_DIR\"
  git fetch --all --prune
  git checkout --force \"\$DEPLOY_SHA\"
  git reset --hard \"\$DEPLOY_SHA\"
  git clean -fd

  # Place runtime env at repo root so browse-server/server.js can load ../.env
  if [ -f /tmp/deeptime.env ]; then
    mv /tmp/deeptime.env \"\$APP_DIR/.env\"
  fi

  cd \"\$APP_DIR/browse-server\"

  # Install production deps for exactly this lockfile
  npm ci --omit=dev --silent

  # Start/restart app with PM2
  if pm2 describe leaflet-viewer >/dev/null 2>&1; then
    pm2 restart leaflet-viewer --update-env
  else
    pm2 start server.js --name leaflet-viewer --cwd \"\$APP_DIR/browse-server\" -- --production
  fi

  pm2 save

  echo ''
  echo 'Deployed SHA:'
  git rev-parse --short HEAD
  pm2 list
"

echo ""
echo "Deployment complete"
echo "App URL: http://${VM_STATIC_IP:-your-ip}:${PORT:-8081}"
echo "SHA: $DEPLOY_SHA"
echo ""