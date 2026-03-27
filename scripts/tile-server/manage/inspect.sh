#!/bin/bash
# Show detailed information about a COG file in GCS

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

source "$PROJECT_ROOT/.env"

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
VSIGS_PATH="/vsigs/${BUCKET_NAME}/${FILE_NAME}"

# Check if file exists
if ! gcloud storage ls "$FILE_PATH" &>/dev/null; then
  echo "Error: File not found: $FILE_PATH"
  exit 1
fi

# Set up GCS credentials for GDAL
if [ -f "$PROJECT_ROOT/keys/titiler-sa-key.json" ]; then
  export GOOGLE_APPLICATION_CREDENTIALS="$PROJECT_ROOT/keys/titiler-sa-key.json"
fi

echo "========================================="
echo "COG File Information"
echo "========================================="
echo "File: $FILE_PATH"
echo ""

# GCS file info
echo "--- GCS Storage Info ---"
gcloud storage ls -L "$FILE_PATH" | grep -E 'Content-Type|Hash \(CRC32C\)|Storage class|Size:' | sed 's/^[[:space:]]*/ /'
echo ""

# GDAL info using /vsigs/ virtual filesystem
echo "--- Raster Metadata ---"
if ! command -v gdalinfo &>/dev/null; then
  echo "❌ gdalinfo not available"
  exit 1
fi

GDALINFO_OUTPUT=$(gdalinfo "$VSIGS_PATH" 2>&1)
if [ $? -ne 0 ]; then
  echo "❌ Cannot read file with GDAL"
  echo "$GDALINFO_OUTPUT" | grep -i error
  exit 1
fi

# Extract key information
echo "$GDALINFO_OUTPUT" | grep "Size is"
echo "$GDALINFO_OUTPUT" | grep "Coordinate System" | head -1
echo "$GDALINFO_OUTPUT" | grep "Origin ="
echo "$GDALINFO_OUTPUT" | grep "Pixel Size ="
echo ""

# Corner coordinates
echo "--- Geographic Bounds ---"
echo "$GDALINFO_OUTPUT" | grep -A 5 "Corner Coordinates"
echo ""

# Custom metadata
echo "--- Custom Metadata ---"
METADATA=$(echo "$GDALINFO_OUTPUT" | sed -n '/^Metadata:$/,/^[A-Z]/p' | grep -E "^  [A-Z]" | grep -E "SITE_NAME|SCALE_|ZOOM|GEOREF|PROCESSING_DATE|SOURCE_FILE_COUNT|COMMENT")

if [ -n "$METADATA" ]; then
  echo "$METADATA"
else
  echo "  No custom metadata found"
fi
echo ""

# COG validation
if command -v rio &>/dev/null; then
  echo "--- COG Validation ---"
  if rio cogeo validate "$VSIGS_PATH" 2>&1 | grep -q "is a valid"; then
    echo "✅ Valid Cloud-Optimized GeoTIFF"
  else
    echo "❌ Not a valid COG format"
    rio cogeo validate "$VSIGS_PATH" 2>&1 | tail -3
  fi
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
