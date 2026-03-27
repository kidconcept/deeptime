#!/bin/bash
# Remove a COG file from the GCS bucket

source .env

BUCKET_NAME=${BUCKET_NAME:-}
FILE_NAME=${1:-}

if [ -z "$BUCKET_NAME" ]; then
  echo "Error: BUCKET_NAME not set in .env"
  exit 1
fi

if [ -z "$FILE_NAME" ]; then
  echo "Usage: cog remove <filename.tif>"
  echo ""
  echo "Available files:"
  gcloud storage ls "gs://${BUCKET_NAME}/" | grep -E '\.tif$|\.tiff$'
  exit 1
fi

FILE_PATH="gs://${BUCKET_NAME}/${FILE_NAME}"

# Check if file exists
if ! gcloud storage ls "$FILE_PATH" &>/dev/null; then
  echo "Error: File not found: $FILE_PATH"
  exit 1
fi

echo "========================================="
echo "Remove COG File"
echo "========================================="
echo "File: $FILE_PATH"
echo ""

# Confirm deletion
read -p "Are you sure you want to delete this file? (y/N) " confirm

if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
  echo "Cancelled"
  exit 0
fi

# Delete the file
echo "Deleting..."
gcloud storage rm "$FILE_PATH"

if [ $? -eq 0 ]; then
  echo "✅ File deleted successfully"
  
  # Update .env if this was the active COG
  if grep -q "COG_GCS_URI=${FILE_PATH}" .env 2>/dev/null; then
    echo ""
    echo "⚠️  Warning: This was the active COG in .env"
    echo "   Update COG_GCS_URI in .env to point to a different file"
  fi
else
  echo "❌ Failed to delete file"
  exit 1
fi
