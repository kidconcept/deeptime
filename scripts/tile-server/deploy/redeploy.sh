#!/bin/bash
# Quick redeployment script for new GCP project

set -e

NEW_PROJECT_ID=${1:-}
NEW_BUCKET_NAME=${2:-}

if [ -z "$NEW_PROJECT_ID" ] || [ -z "$NEW_BUCKET_NAME" ]; then
  echo "Usage: $0 NEW-PROJECT-ID NEW-BUCKET-NAME"
  exit 1
fi

echo "========================================="
echo "Redeploying TiTiler to New Project"
echo "========================================="
echo "New Project: $NEW_PROJECT_ID"
echo "New Bucket: $NEW_BUCKET_NAME"
echo ""

# Set project
gcloud config set project $NEW_PROJECT_ID

# Enable APIs
echo "Enabling required APIs..."
gcloud services enable run.googleapis.com storage.googleapis.com

# Create service account
bash scripts/tile-server/setup-sa.sh $NEW_PROJECT_ID

# Update .env
cat > .env << EOF
PROJECT_ID=$NEW_PROJECT_ID
BUCKET_NAME=$NEW_BUCKET_NAME
REGION=us-central1
TITILER_SA_EMAIL=titiler-sa@${NEW_PROJECT_ID}.iam.gserviceaccount.com
EOF

echo ""
echo ".env file updated"
echo ""
echo "Next steps:"
echo "1. Upload COGs: gcloud storage cp *.tif gs://${NEW_BUCKET_NAME}/"
echo "2. Update COG_GCS_URI in .env"
echo "3. Deploy: bash scripts/tile-server/deploy.sh"
