#!/bin/bash
# Deploy TiTiler to Cloud Run with tested configuration

set -e

# Get script directory and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Load environment variables from repo root
source "$REPO_ROOT/.env" 2>/dev/null || true

PROJECT_ID=${PROJECT_ID:-$(gcloud config get-value project)}
SERVICE_NAME="titiler"
REGION=${REGION:-"us-central1"}
SERVICE_ACCOUNT=${TITILER_SA_EMAIL:-"titiler-sa@${PROJECT_ID}.iam.gserviceaccount.com"}

echo "========================================="
echo "Deploying TiTiler to Cloud Run"
echo "========================================="
echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Service Account: $SERVICE_ACCOUNT"
echo ""

gcloud run deploy $SERVICE_NAME \
  --image=ghcr.io/developmentseed/titiler:latest \
  --region=$REGION \
  --platform=managed \
  --allow-unauthenticated \
  --service-account=$SERVICE_ACCOUNT \
  --memory=2Gi \
  --cpu=2 \
  --timeout=300 \
  --max-instances=10 \
  --port=8000 \
  --set-env-vars="GDAL_DISABLE_READDIR_ON_OPEN=EMPTY_DIR,CPL_VSIL_CURL_ALLOWED_EXTENSIONS=.tif,GDAL_HTTP_MERGE_CONSECUTIVE_RANGES=YES,GDAL_HTTP_MULTIPLEX=YES,GDAL_HTTP_VERSION=2"

echo ""
echo "========================================="
echo "Deployment Complete!"
echo "========================================="

# Get service URL
TITILER_URL=$(gcloud run services describe $SERVICE_NAME --region=$REGION --format="value(status.url)")
echo "TiTiler URL: $TITILER_URL"

# Update root .env
ENV_FILE="$REPO_ROOT/.env"
if grep -q "^TITILER_URL=" "$ENV_FILE" 2>/dev/null; then
  sed -i.bak "s|^TITILER_URL=.*|TITILER_URL=${TITILER_URL}|" "$ENV_FILE" && rm -f "${ENV_FILE}.bak"
else
  echo "TITILER_URL=${TITILER_URL}" >> "$ENV_FILE"
fi
echo "Updated $ENV_FILE"

echo ""
echo "Testing deployment..."
bash scripts/tile-server/test.sh
