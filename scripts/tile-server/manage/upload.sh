#!/bin/bash
# Upload a COG file to the GCS bucket

source .env

BUCKET_NAME=${BUCKET_NAME:-}
LOCAL_FILE=${1:-}
REMOTE_NAME=${2:-}

if [ -z "$BUCKET_NAME" ]; then
  echo "Error: BUCKET_NAME not set in .env"
  exit 1
fi

if [ -z "$LOCAL_FILE" ]; then
  echo "Usage: cog upload <local-file.tif> [remote-name.tif]"
  echo ""
  echo "Examples:"
  echo "  cog upload /path/to/coral.tif"
  echo "  cog upload /path/to/coral.tif site1-2024.tif"
  exit 1
fi

# Check if local file exists
if [ ! -f "$LOCAL_FILE" ]; then
  echo "Error: File not found: $LOCAL_FILE"
  exit 1
fi

# Use original filename if no remote name provided
if [ -z "$REMOTE_NAME" ]; then
  REMOTE_NAME=$(basename "$LOCAL_FILE")
fi

REMOTE_PATH="gs://${BUCKET_NAME}/${REMOTE_NAME}"

echo "========================================="
echo "Upload COG File"
echo "========================================="
echo "Local:  $LOCAL_FILE"
echo "Remote: $REMOTE_PATH"
echo ""

# Check file size
FILE_SIZE=$(du -h "$LOCAL_FILE" | cut -f1)
echo "File size: $FILE_SIZE"
echo ""

# Validate it's a valid TIFF/COG (if rio is installed)
if command -v rio &>/dev/null; then
  echo "Validating COG format..."
  if rio cogeo validate "$LOCAL_FILE" &>/dev/null; then
    echo "✅ Valid COG format"
  else
    echo "⚠️  Warning: Not a valid COG (will still upload)"
    echo "   Consider converting with: gdal_translate -of COG input.tif output.tif"
  fi
  echo ""
fi

# Upload the file
echo "Uploading..."
gcloud storage cp "$LOCAL_FILE" "$REMOTE_PATH"

if [ $? -eq 0 ]; then
  echo ""
  echo "========================================="
  echo "✅ Upload Complete!"
  echo "========================================="
  echo "GCS URI: $REMOTE_PATH"
  echo ""
  echo "Test with TiTiler:"
  echo "  curl \"${TITILER_URL}/cog/info?url=${REMOTE_PATH}\""
  echo ""
  echo "Inspect the file:"
  echo "  cog inspect ${REMOTE_NAME}"
  echo ""
  echo "To set as active COG, add to .env:"
  echo "  COG_GCS_URI=${REMOTE_PATH}"
else
  echo "❌ Upload failed"
  exit 1
fi
