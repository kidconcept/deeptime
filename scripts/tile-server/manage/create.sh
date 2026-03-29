#!/bin/bash
set -e

# Cleanup on exit
trap 'rm -f temp.vrt' EXIT

# Default configuration
PIXEL_SIZE_M=0.00069
ARBITRARY_MODE=false
INPUT_PATH=""
OUTPUT=""
SITE_NAME=""

# Check required tools
for tool in gdalbuildvrt gdalinfo python3 rio; do
  if ! command -v $tool &> /dev/null; then
    echo "Error: $tool not found"
    exit 1
  fi
done

if ! command -v /opt/homebrew/bin/gdal_edit.py &> /dev/null; then
  echo "Error: /opt/homebrew/bin/gdal_edit.py not found"
  exit 1
fi

# Helper function
show_usage() {
  cat << EOF
Usage: cog create [OPTIONS] <input> [output]

Create a Cloud-Optimized GeoTIFF with optimal settings for TiTiler display.

Modes:
  Default        Preserve existing georeferencing
  --arbitrary    Add arbitrary georeferencing (EPSG:3857) at (0,0)

Arguments:
  input          Path to source file or folder
  output         Output COG path (optional, defaults to output.tif)

Options:
  -a, --arbitrary           Use arbitrary (0,0) georeferencing in EPSG:3857
  -s, --sitename <name>     Site name for metadata
  -h, --help                Show this help message

Examples:
  cog create /path/to/scan.tif output.tif
  cog create /path/to/geotiffs/ output.tif
  cog create --arbitrary --sitename "18 Palms" /path/to/geotiffs/
EOF
  exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    -a|--arbitrary)
      ARBITRARY_MODE=true
      shift
      ;;
    -s|--sitename)
      SITE_NAME="$2"
      shift 2
      ;;
    -h|--help)
      show_usage
      ;;
    *)
      if [ -z "$INPUT_PATH" ]; then
        INPUT_PATH="$1"
      elif [ -z "$OUTPUT" ]; then
        OUTPUT="$1"
      fi
      shift
      ;;
  esac
done

# Validate input
if [ -z "$INPUT_PATH" ]; then
  echo "Error: Input path required"
  show_usage
fi

if [ ! -e "$INPUT_PATH" ]; then
  echo "Error: Input path does not exist: $INPUT_PATH"
  exit 1
fi

# Default output
if [ -z "$OUTPUT" ]; then
  # Determine base name for output
  if [ -n "$SITE_NAME" ]; then
    # Use site name (sanitized) if provided
    BASE_NAME=$(echo "$SITE_NAME" | tr ' ' '-')
  elif [ -d "$INPUT_PATH" ]; then
    # For directory input: use directory name
    BASE_NAME=$(basename "$INPUT_PATH")
  else
    # For file input: use file basename
    BASE_NAME=$(basename "$INPUT_PATH" .tif)
    BASE_NAME=$(basename "$BASE_NAME" .tiff)
  fi
  
  # Construct output path
  OUTPUT_DIR=$(dirname "$INPUT_PATH")
  if [ "$ARBITRARY_MODE" = true ]; then
    OUTPUT="$OUTPUT_DIR/${BASE_NAME}-arbitrary-cog.tif"
  else
    OUTPUT="$OUTPUT_DIR/${BASE_NAME}-cog.tif"
  fi
fi

# Build VRT from file or folder
if [ -d "$INPUT_PATH" ]; then
  echo "Building VRT from folder $INPUT_PATH..."
  
  # Check for tif files
  shopt -s nullglob
  TIF_FILES=("$INPUT_PATH"/*.tif "$INPUT_PATH"/*.tiff)
  shopt -u nullglob
  
  if [ ${#TIF_FILES[@]} -eq 0 ]; then
    echo "Error: No .tif or .tiff files found in $INPUT_PATH"
    exit 1
  fi
  
  # Use -allow_projection_difference in arbitrary mode to handle mixed/missing CRS
  if [ "$ARBITRARY_MODE" = true ]; then
    gdalbuildvrt -allow_projection_difference temp.vrt "${TIF_FILES[@]}"
  else
    gdalbuildvrt temp.vrt "${TIF_FILES[@]}"
  fi
elif [ -f "$INPUT_PATH" ]; then
  echo "Building VRT from file $INPUT_PATH..."
  gdalbuildvrt temp.vrt "$INPUT_PATH"
else
  echo "Error: Input must be a file or directory"
  exit 1
fi

# Get dimensions
DIMS=$(gdalinfo temp.vrt | grep "Size is" | sed 's/Size is //')
WIDTH=$(echo $DIMS | cut -d',' -f1)
HEIGHT=$(echo $DIMS | cut -d',' -f2 | xargs)
BAND_COUNT=$(gdalinfo temp.vrt | grep -c "^Band [0-9]")

echo "Dimensions: ${WIDTH}x${HEIGHT}, Bands: ${BAND_COUNT}"

# Apply georeferencing based on mode
if [ "$ARBITRARY_MODE" = true ]; then
  echo "Applying arbitrary georeferencing (EPSG:3857 at origin 0,0)..."
  
  # Calculate extent in meters
  WIDTH_M=$(python3 -c "print($WIDTH * $PIXEL_SIZE_M)")
  HEIGHT_M=$(python3 -c "print($HEIGHT * $PIXEL_SIZE_M)")
  
  echo "Extent: [0, 0, $WIDTH_M, $HEIGHT_M] meters"
  
  # Apply CRS and georeference at (0,0)
  /opt/homebrew/bin/gdal_edit.py -a_srs EPSG:3857 -a_ullr 0 $HEIGHT_M $WIDTH_M 0 temp.vrt
else
  echo "Preserving existing georeferencing..."
fi

# Add site name metadata if provided
if [ -n "$SITE_NAME" ]; then
  echo "Adding site name metadata: $SITE_NAME"
  /opt/homebrew/bin/gdal_edit.py -mo "SITE_NAME=${SITE_NAME}" temp.vrt
fi

# Determine compression based on band count
if [ "$BAND_COUNT" -ge 3 ]; then
  PROFILE="jpeg"
  QUALITY="--co JPEG_QUALITY=85"
  echo "Using JPEG compression (RGB imagery)"
else
  PROFILE="lzw"
  QUALITY=""
  echo "Using LZW compression (grayscale/single-band)"
fi

# Calculate overview levels
SMALLEST=$(python3 -c "print(min($WIDTH, $HEIGHT))")
OVERVIEWS=$(python3 -c "import math; print(max(1, int(math.log2($SMALLEST / 512))))")

echo "Overview levels: $OVERVIEWS"

# Create COG
echo "Creating COG..."
rio cogeo create \
  --cog-profile "$PROFILE" \
  ${QUALITY} \
  --blocksize 512 \
  --overview-blocksize 512 \
  --overview-level "$OVERVIEWS" \
  --overview-resampling bilinear \
  --resampling bilinear \
  --threads 4 \
  temp.vrt "$OUTPUT"

# Validate COG
echo ""
echo "Validating COG..."
if rio cogeo validate "$OUTPUT"; then
  echo "✓ COG validation passed"
else
  echo "⚠️  COG validation failed"
  exit 1
fi

# Show final COG info
echo ""
echo "========================================="
echo "COG Information:"
echo "========================================="
# Check CRS (match both WKT1 AUTHORITY and WKT2 ID formats)
# Use tail -1 to get the last EPSG code, which is the projected CRS in WKT2
CRS_CHECK=$(gdalinfo "$OUTPUT" | grep -E "(AUTHORITY|ID)\[\"EPSG\"" | tail -1)
if [ -n "$CRS_CHECK" ] && ! echo "$CRS_CHECK" | grep -q "3857"; then
  echo ""
  echo "⚠️  Warning: COG CRS is not EPSG:3857 (Web Mercator)"
  echo "   Expected EPSG:3857 for optimal Leaflet/CVAT performance."
elif [ -z "$CRS_CHECK" ]; then
  echo ""
  echo "⚠️  Warning: No CRS detected in COG"
  echo "   TiTiler may not be able to display this file properly."
fi

gdalinfo "$OUTPUT"

echo ""
echo "✓ COG created: $OUTPUT"