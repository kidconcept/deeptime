#!/bin/bash
# Show detailed information about a COG file in GCS

source .env

BUCKET_NAME=${BUCKET_NAME:-}
FILE_NAME=${1:-}

if [ -z "$BUCKET_NAME" ]; then
  echo "Error: BUCKET_NAME not set in .env"
  exit 1
fi

if [ -z "$FILE_NAME" ]; then
  echo "Usage: cog inspect <filename.tif>"
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
echo "COG File Information"
echo "========================================="
echo "File: $FILE_PATH"
echo ""

# GCS file info
echo "--- GCS Metadata ---"
gcloud storage ls -L "$FILE_PATH" | grep -E 'Creation time|Update time|Size|Content-Type|CRC32C'
echo ""

# GDAL info (if available)
if command -v gdalinfo &>/dev/null; then
  echo "--- Raster Metadata ---"
  gdalinfo "$FILE_PATH" | grep -A 3 "Size is"
  echo ""
  gdalinfo "$FILE_PATH" | grep -A 5 "Corner Coordinates"
  echo ""
  gdalinfo "$FILE_PATH" | grep "Pixel Size"
  echo ""
  
  # Check if it's a valid COG
  if command -v rio &>/dev/null; then
    echo "--- COG Validation ---"
    if rio cogeo validate "$FILE_PATH" 2>&1 | grep -q "is a valid"; then
      echo "✅ Valid COG format"
    else
      echo "❌ Not a valid COG"
      rio cogeo validate "$FILE_PATH" 2>&1 | tail -5
    fi
    echo ""
  fi
fi

# TiTiler info
echo "--- TiTiler Info ---"
echo "Testing TiTiler endpoints..."
ENCODED_URL=$(python3 -c "import urllib.parse; print(urllib.parse.quote('${FILE_PATH}', safe=''))")

# Info endpoint
INFO_RESPONSE=$(curl -sf "${TITILER_URL}/cog/info?url=${ENCODED_URL}" 2>/dev/null)
if [ $? -eq 0 ]; then
  echo "✅ TiTiler can read this file"
  echo "   Bounds: $(echo $INFO_RESPONSE | grep -o '"bounds":\[[^]]*\]')"
  echo "   Dimensions: $(echo $INFO_RESPONSE | grep -o '"width":[0-9]*' | cut -d: -f2) x $(echo $INFO_RESPONSE | grep -o '"height":[0-9]*' | cut -d: -f2)"
  echo "   Zoom levels: $(echo $INFO_RESPONSE | grep -o '"minzoom":[0-9]*' | cut -d: -f2) - $(echo $INFO_RESPONSE | grep -o '"maxzoom":[0-9]*' | cut -d: -f2)"
else
  echo "❌ TiTiler cannot read this file"
  echo "   Check service account permissions and file format"
fi

echo ""
echo "========================================="
echo "Quick Actions"
echo "========================================="
echo "Set as active COG:"
echo "  echo 'COG_GCS_URI=${FILE_PATH}' >> .env"
echo ""
echo "Download locally:"
echo "  gcloud storage cp ${FILE_PATH} ."
echo ""
echo "View in browser (preview):"
echo "  open \"${TITILER_URL}/cog/preview.png?url=${ENCODED_URL}&max_size=1024\""
