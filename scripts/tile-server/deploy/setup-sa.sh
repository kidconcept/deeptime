#!/bin/bash
# Create and configure TiTiler service account

PROJECT_ID=${1:-$(gcloud config get-value project)}
SA_NAME="titiler-sa"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "========================================="
echo "Creating TiTiler Service Account"
echo "========================================="
echo "Project: $PROJECT_ID"
echo "Service Account: $SA_EMAIL"
echo ""

# Check if service account exists
if gcloud iam service-accounts describe $SA_EMAIL --project=$PROJECT_ID &>/dev/null; then
  echo "Service account already exists"
else
  echo "Creating service account..."
  gcloud iam service-accounts create $SA_NAME \
    --display-name="TiTiler Service Account" \
    --project=$PROJECT_ID
fi

# Grant Storage Object Viewer role
echo "Granting Storage Object Viewer role..."
gcloud projects add-iam-policy-binding $PROJECT_ID \
  --member="serviceAccount:${SA_EMAIL}" \
  --role="roles/storage.objectViewer"

echo ""
echo "========================================="
echo "Service Account Ready!"
echo "========================================="
echo "Email: $SA_EMAIL"
echo ""
echo "Add to .env file:"
echo "TITILER_SA_EMAIL=${SA_EMAIL}"
