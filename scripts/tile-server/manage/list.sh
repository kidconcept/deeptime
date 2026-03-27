#!/bin/bash
# List all COG files in the GCS bucket

source .env

BUCKET_NAME=${BUCKET_NAME:-}

if [ -z "$BUCKET_NAME" ]; then
  echo "Error: BUCKET_NAME not set in .env"
  exit 1
fi

echo "========================================="
echo "COG Files in Bucket"
echo "========================================="
echo "Bucket: gs://${BUCKET_NAME}"
echo ""

# List all files with details
gcloud storage ls -l "gs://${BUCKET_NAME}/" | grep -E '\.tif$|\.tiff$|Total'

echo ""
echo "To view a specific file's metadata:"
echo "  cog inspect <filename.tif>"
echo ""
echo "To test a COG with TiTiler:"
echo "  curl \"${TITILER_URL}/cog/info?url=gs://${BUCKET_NAME}/filename.tif\""
