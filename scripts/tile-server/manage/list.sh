#!/bin/bash
# List all COG files in the GCS bucket

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$PROJECT_ROOT/.env"

BUCKET_NAME=${BUCKET_NAME:-}

if [ -z "$BUCKET_NAME" ]; then
  echo "Error: BUCKET_NAME not set in .env"
  exit 1
fi

# Set up GCS credentials for GDAL
if [ -f "$PROJECT_ROOT/keys/titiler-sa-key.json" ]; then
  export GOOGLE_APPLICATION_CREDENTIALS="$PROJECT_ROOT/keys/titiler-sa-key.json"
fi

echo "========================================="
echo "COG Files in Bucket"
echo "========================================="
echo "Bucket: gs://${BUCKET_NAME}"
echo ""

# Get list of COG files
FILES=$(gcloud storage ls "gs://${BUCKET_NAME}/" | grep -E '\.tif$|\.tiff$')

if [ -z "$FILES" ]; then
  echo "No COG files found in bucket."
  exit 0
fi

# Display header
printf "%-40s %-10s %s\n" "FILENAME" "SIZE" "SITE NAME"
echo "--------------------------------------------------------------------------------"

# Process each file sequentially
echo "$FILES" | while read -r FILE_URL; do
  FILENAME=$(basename "$FILE_URL")
  
  # Get file size
  SIZE=$(gcloud storage ls -l "$FILE_URL" | grep -v TOTAL | awk '{print $1}')
  if [ -z "$SIZE" ]; then
    SIZE="?"
  else
    # Convert bytes to human readable
    if command -v numfmt &> /dev/null; then
      SIZE=$(numfmt --to=iec-i --suffix=B --format="%.1f" "$SIZE" 2>/dev/null || echo "$SIZE")
    fi
  fi
  
  # Get SITE_NAME from file metadata using GDAL
  SITE_NAME=""
  if command -v gdalinfo &>/dev/null; then
    VSIGS_PATH="/vsigs/${BUCKET_NAME}/${FILENAME}"
    SITE_NAME=$(gdalinfo "$VSIGS_PATH" 2>/dev/null | grep "SITE_NAME=" | sed 's/.*SITE_NAME=//' | head -1)
  fi
  
  if [ -z "$SITE_NAME" ]; then
    SITE_NAME="-"
  fi
  
  printf "%-40s %-10s %s\n" "$FILENAME" "$SIZE" "$SITE_NAME"
done

echo ""
echo "To view detailed metadata:"
echo "  cog inspect <filename.tif>"
