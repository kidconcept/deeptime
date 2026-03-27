#!/bin/bash
# Create a Cloud-Optimized GeoTIFF from source files
# Supports two modes:
#   1. Preserve existing georeferencing (default)
#   2. Add arbitrary georeferencing at (0,0) with --arbitrary flag
#
# Version: 1.0.0

set -e

# Configuration
TEMP_DIR="/tmp/deeptime-cog-$$"
DEFAULT_SCALE_M_PER_PX=0.00069
METERS_PER_DEGREE=111320.0
WEB_MERCATOR_M0=156543.03
ANCHOR_LON=0.0
ANCHOR_LAT=0.0

# Parse arguments
ARBITRARY_MODE=false
INPUT_PATH=""
OUTPUT_PATH=""
SITE_NAME=""
METADATA_SUCCESS=false  # Track if metadata was added successfully

# =============================================================================
# Helper Functions
# =============================================================================

# Get compression settings for rio cogeo create
get_cog_compression() {
  local band_count=$1
  if [ "$band_count" -ge 3 ]; then
    echo "jpeg --co JPEG_QUALITY=85"
  else
    echo "lzw"
  fi
}

# Get compression label for display
get_compression_label() {
  local band_count=$1
  if [ "$band_count" -ge 3 ]; then
    echo "JPEG compression with quality 85% (photographic imagery)"
  else
    echo "LZW compression (non-photographic data)"
  fi
}

# Add metadata to a VRT file using gdal_edit.py
add_metadata_to_vrt() {
  local file=$1
  
  # Use Homebrew's gdal_edit.py (pyenv version has broken GDAL bindings)
  local GDAL_EDIT="/opt/homebrew/bin/gdal_edit.py"
  
  if ! command -v "$GDAL_EDIT" &> /dev/null; then
    echo "   ⚠️  $GDAL_EDIT not available - skipping metadata"
    return 1
  fi
  
  # Build metadata arguments
  local meta_args=(
    "-mo" "SCALE_M_PER_PX=${SCALE_M}"
    "-mo" "SCALE_SOURCE=${SCALE_SOURCE}"
    "-mo" "IMAGE_WIDTH=${WIDTH}"
    "-mo" "IMAGE_HEIGHT=${HEIGHT}"
    "-mo" "NATIVE_ZOOM_LEVEL=${NATIVE_ZOOM}"
    "-mo" "RECOMMENDED_MIN_ZOOM=${MIN_ZOOM}"
    "-mo" "RECOMMENDED_MAX_ZOOM=${MAX_ZOOM}"
    "-mo" "SITE_NAME=${SITE_NAME}"
    "-mo" "SOURCE_FILE_COUNT=${SOURCE_COUNT}"
    "-mo" "PROCESSING_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
  )
  
  # Add arbitrary-specific metadata if applicable
  if [ "$ARBITRARY_MODE" = true ]; then
    meta_args+=(
      "-mo" "COORDINATE_SYSTEM=unreferenced"
      "-mo" "GEOREF_METHOD=arbitrary"
      "-mo" "GEOREF_ANCHOR=lower_left_at_0_0"
      "-mo" "GEOREF_DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)"
      "-mo" "COMMENT=Arbitrary georeferencing for visualization only. Not real-world coordinates."
    )
  fi
  
  if "$GDAL_EDIT" "${meta_args[@]}" "$file"; then
    echo "   Metadata added"
    return 0
  else
    echo "   ⚠️  Metadata update failed (see error above)"
    return 1
  fi
}

show_usage() {
  cat << EOF
Usage: cog create [OPTIONS] <input> [output]

Create a Cloud-Optimized GeoTIFF with optimal settings for TiTiler display.

Modes:
  Default        Preserve existing georeferencing (for properly georeferenced files)
  --arbitrary    Add arbitrary georeferencing at (0,0) for non-georeferenced files

Arguments:
  input          Path to source file or directory
                 - Single file: Converts to COG preserving georeferencing
                 - Directory: Builds VRT from all geotiffs, then converts to COG
  output         Output COG path (optional, auto-generated if not provided)

Options:
  -a, --arbitrary         Use arbitrary (0,0) georeferencing instead of preserving existing
  -s, --site-name <name>  Site name for metadata (optional, derived from filename)
  -h, --help              Show this help message

Examples:
  # Single properly georeferenced file
  cog create /path/to/scan.tif output.tif

  # Directory of non-georeferenced tiles with arbitrary georeferencing
  cog create --arbitrary --site-name "18 Palms Unreferenced" /path/to/GIS/tiles/

  # Auto-generate output name with custom site name
  cog create --site-name "Site 1" /path/to/scan.tif

EOF
  exit 0
}

# Parse options
while [[ $# -gt 0 ]]; do
  case $1 in
    -a|--arbitrary)
      ARBITRARY_MODE=true
      shift
      ;;
    -s|--site-name)
      SITE_NAME="$2"
      shift 2
      ;;
    -h|--help)
      show_usage
      ;;
    *)
      if [ -z "$INPUT_PATH" ]; then
        INPUT_PATH="$1"
      elif [ -z "$OUTPUT_PATH" ]; then
        OUTPUT_PATH="$1"
      fi
      shift
      ;;
  esac
done

# Validate input
if [ -z "$INPUT_PATH" ]; then
  echo "Error: Input path required"
  echo ""
  show_usage
fi

if [ ! -e "$INPUT_PATH" ]; then
  echo "Error: Input path does not exist: $INPUT_PATH"
  exit 1
fi

# Determine if input is directory or file
if [ -d "$INPUT_PATH" ]; then
  IS_DIRECTORY=true
  INPUT_TYPE="directory"
else
  IS_DIRECTORY=false
  INPUT_TYPE="file"
fi

# Auto-generate output path if not provided
if [ -z "$OUTPUT_PATH" ]; then
  if [ "$IS_DIRECTORY" = true ]; then
    PARENT_NAME=$(basename "$(dirname "$INPUT_PATH")")
    OUTPUT_DIR="$(dirname "$INPUT_PATH")/COG"
    mkdir -p "$OUTPUT_DIR"
    if [ "$ARBITRARY_MODE" = true ]; then
      OUTPUT_PATH="$OUTPUT_DIR/${PARENT_NAME}-arbitrary-cog.tif"
    else
      OUTPUT_PATH="$OUTPUT_DIR/${PARENT_NAME}-cog.tif"
    fi
  else
    BASE_NAME=$(basename "$INPUT_PATH" .tif)
    OUTPUT_DIR=$(dirname "$INPUT_PATH")
    if [ "$ARBITRARY_MODE" = true ]; then
      OUTPUT_PATH="${OUTPUT_DIR}/${BASE_NAME}-arbitrary-cog.tif"
    else
      OUTPUT_PATH="${OUTPUT_DIR}/${BASE_NAME}-cog.tif"
    fi
  fi
fi

# Auto-generate site name if not provided
if [ -z "$SITE_NAME" ]; then
  SITE_NAME=$(basename "$OUTPUT_PATH" .tif)
fi

echo "======================================================================="
echo "  COG Creation Tool v1.0.0"
echo "======================================================================="
echo ""
echo "Mode:        $([ "$ARBITRARY_MODE" = true ] && echo "Arbitrary georeferencing (0,0)" || echo "Preserve existing georeferencing")"
echo "Input:       $INPUT_PATH"
echo "Output:      $OUTPUT_PATH"
echo "Site name:   $SITE_NAME"
echo ""

# =============================================================================
# Create working directory
# =============================================================================

mkdir -p "$TEMP_DIR"
cd "$TEMP_DIR"

# =============================================================================
# STEP 1: Prepare source (VRT for directory, copy for single file)
# =============================================================================

echo "📥 Step 1: Preparing source..."

# Always create VRT to allow metadata addition
if [ "$IS_DIRECTORY" = true ]; then
  # Build VRT from directory
  SOURCE_COUNT=$(find "$INPUT_PATH" -name "*.tif" -o -name "*.tiff" | wc -l | xargs)
  echo "   Found $SOURCE_COUNT geotiff files in directory"
  
  if [ "$SOURCE_COUNT" -eq 0 ]; then
    echo "❌ Error: No geotiff files found in $INPUT_PATH"
    rm -rf "$TEMP_DIR"
    exit 1
  fi
  
  gdalbuildvrt -overwrite source.vrt "$INPUT_PATH"/*.tif
  echo "   VRT created from $SOURCE_COUNT files"
else
  # Single file - create VRT wrapper to allow metadata addition
  SOURCE_COUNT=1
  echo "   Creating VRT wrapper for: $(basename "$INPUT_PATH")"
  gdalbuildvrt -overwrite source.vrt "$INPUT_PATH"
  echo "   VRT wrapper created"
fi

SOURCE_FILE="source.vrt"

# =============================================================================
# STEP 2: Analyze source
# =============================================================================

echo ""
echo "📊 Step 2: Analyzing source..."

GDALINFO_OUTPUT=$(gdalinfo "$SOURCE_FILE")
DIMENSIONS=$(echo "$GDALINFO_OUTPUT" | grep "Size is" | sed 's/Size is //')
WIDTH=$(echo $DIMENSIONS | cut -d',' -f1)
HEIGHT=$(echo $DIMENSIONS | cut -d',' -f2 | xargs)
BAND_COUNT=$(echo "$GDALINFO_OUTPUT" | grep -c "^Band [0-9]")

echo "   Image size: ${WIDTH} x ${HEIGHT} pixels"
echo "   Band count: ${BAND_COUNT}"

# Detect pixel scale based on mode
if [ "$ARBITRARY_MODE" = true ]; then
  # Arbitrary mode: source isn't georeferenced, always use default
  SCALE_M=$DEFAULT_SCALE_M_PER_PX
  PIXEL_SIZE_DEG=$(echo "scale=15; $SCALE_M / $METERS_PER_DEGREE" | bc)
  SCALE_SOURCE="default"
else
  # Default mode: trust the existing geotransform
  PIXEL_SIZE_LINE=$(echo "$GDALINFO_OUTPUT" | grep "Pixel Size =" || echo "")
  if [ -n "$PIXEL_SIZE_LINE" ]; then
    PIXEL_SIZE_DEG=$(echo "$PIXEL_SIZE_LINE" | sed -E 's/.*\(([0-9.e+-]+).*/\1/' | sed 's/^-//')
    SCALE_M=$(echo "scale=15; $PIXEL_SIZE_DEG * $METERS_PER_DEGREE" | bc)
    SCALE_SOURCE="geotransform"
  else
    SCALE_M=$DEFAULT_SCALE_M_PER_PX
    PIXEL_SIZE_DEG=$(echo "scale=15; $SCALE_M / $METERS_PER_DEGREE" | bc)
    SCALE_SOURCE="default"
  fi
fi

echo "   Pixel scale: ${SCALE_M} m/pixel (${SCALE_SOURCE})"

# =============================================================================
# STEP 3: Calculate display parameters
# =============================================================================

echo ""
echo "📐 Step 3: Calculating display parameters..."

# Calculate optimal zoom levels
if command -v python3 &> /dev/null; then
  NATIVE_ZOOM=$(python3 -c "import math; print(int(round(math.log2($WEB_MERCATOR_M0 / $SCALE_M))))")
  MIN_ZOOM=$(python3 -c "print(max(0, $NATIVE_ZOOM - 5))")
  MAX_ZOOM=$(python3 -c "print(min(24, $NATIVE_ZOOM + 7))")
  SMALLEST_DIM=$(python3 -c "print(min($WIDTH, $HEIGHT))")
  OVERVIEW_LEVELS=$(python3 -c "import math; print(max(1, int(math.log2($SMALLEST_DIM / 512))))")
else
  NATIVE_ZOOM=12
  MIN_ZOOM=7
  MAX_ZOOM=19
  OVERVIEW_LEVELS=6
fi

echo "   Native zoom: $NATIVE_ZOOM"
echo "   Zoom range: $MIN_ZOOM to $MAX_ZOOM"
echo "   Overview levels: $OVERVIEW_LEVELS"

# =============================================================================
# STEP 4: Apply georeferencing and metadata to VRT (NO pixel copy)
# =============================================================================

echo ""
echo "🏷️  Step 4: Applying georeferencing and metadata..."
if [ "$ARBITRARY_MODE" = true ]; then
  # Calculate extent
  WIDTH_DEG=$(echo "scale=15; $WIDTH * $PIXEL_SIZE_DEG" | bc)
  HEIGHT_DEG=$(echo "scale=15; $HEIGHT * $PIXEL_SIZE_DEG" | bc)
  
  MIN_X=$ANCHOR_LON
  MIN_Y=$ANCHOR_LAT
  MAX_X=$(echo "scale=15; $ANCHOR_LON + $WIDTH_DEG" | bc)
  MAX_Y=$(echo "scale=15; $ANCHOR_LAT + $HEIGHT_DEG" | bc)
  
  echo "   Bounds: [$MIN_X, $MIN_Y, $MAX_X, $MAX_Y]"
  echo "   Anchor: ($ANCHOR_LON, $ANCHOR_LAT)"
  
  # Check if gdal_edit.py is available
  if ! command -v /opt/homebrew/bin/gdal_edit.py &> /dev/null; then
    echo "   ❌ Error: /opt/homebrew/bin/gdal_edit.py not available (required for arbitrary mode)"
    rm -rf "$TEMP_DIR"
    exit 1
  fi
  
  # Update VRT georeferencing
  /opt/homebrew/bin/gdal_edit.py \
    -a_srs EPSG:4326 \
    -a_ullr $MIN_X $MAX_Y $MAX_X $MIN_Y \
    "$SOURCE_FILE"
  
  echo "   Arbitrary EPSG:4326 georeferencing applied"
else
  echo "   Using existing georeferencing from source"
fi

# Add metadata to VRT (will be preserved during COG creation)
if add_metadata_to_vrt "$SOURCE_FILE"; then
  METADATA_SUCCESS=true
else
  echo ""
  echo "   ⚠️  CRITICAL WARNING: Metadata not added!"
  echo "   Without RECOMMENDED_MIN_ZOOM/MAX_ZOOM metadata, the viewer may not"
  echo "   be able to locate this 100m scan in the global view."
  echo "   You may need to manually zoom to find it."
  echo ""
fi

PROCESSING_INPUT="$SOURCE_FILE"

# =============================================================================
# STEP 5: Convert to COG with overviews (metadata from VRT is preserved)
# =============================================================================

echo ""
echo "⚙️  Step 5: Converting to Cloud-Optimized GeoTIFF..."

# Get compression settings
COG_COMPRESSION=$(get_cog_compression $BAND_COUNT)
COMPRESSION_LABEL=$(get_compression_label $BAND_COUNT)

echo "   Using $COMPRESSION_LABEL"

rio cogeo create \
  --cog-profile $(echo $COG_COMPRESSION | cut -d' ' -f1) \
  $(echo $COG_COMPRESSION | cut -d' ' -f2-) \
  --blocksize 512 \
  --overview-blocksize 512 \
  --overview-level $OVERVIEW_LEVELS \
  "$PROCESSING_INPUT" output.tif

echo "   Conversion complete"

# =============================================================================
# STEP 6: Validate and copy to output
# =============================================================================

echo ""
echo "📋 Step 6: Validating and finalizing..."
rio cogeo validate output.tif

# Copy to final destination
echo ""
echo "📤 Copying to output location..."
mkdir -p "$(dirname "$OUTPUT_PATH")"
cp output.tif "$OUTPUT_PATH"

OUTPUT_SIZE=$(du -h "$OUTPUT_PATH" | cut -f1)

# Cleanup
echo ""
echo "🧹 Cleaning up..."
cd - > /dev/null
rm -rf "$TEMP_DIR"

echo ""
echo "✨ SUCCESS! COG created"
echo ""
echo "======================================================================"
echo "📋 COG Information"
echo "======================================================================"
echo ""
echo "Output file:  $OUTPUT_PATH"
echo "File size:    $OUTPUT_SIZE"
echo ""
echo "Site Name: ${SITE_NAME}"
echo "Scale: ${SCALE_M} m/pixel (${SCALE_SOURCE})"
echo "Native zoom: ${NATIVE_ZOOM}"
echo "Zoom range: ${MIN_ZOOM} to ${MAX_ZOOM}"
echo "Overview levels: ${OVERVIEW_LEVELS}"
echo "Size: ${WIDTH} x ${HEIGHT} pixels"

# Extract corner coordinates from the final COG
GDALINFO_FINAL=$(gdalinfo "$OUTPUT_PATH")
UPPER_LEFT=$(echo "$GDALINFO_FINAL" | grep "Upper Left" | sed 's/Upper Left  //')
LOWER_RIGHT=$(echo "$GDALINFO_FINAL" | grep "Lower Right" | sed 's/Lower Right //')

if [ -n "$UPPER_LEFT" ]; then
  echo "North West Corner $UPPER_LEFT"
fi
if [ -n "$LOWER_RIGHT" ]; then
  echo "South East Corner $LOWER_RIGHT"
fi

echo ""
if [ "$ARBITRARY_MODE" = true ]; then
  echo "Mode: Arbitrary georeferencing at (0,0)"
else
  echo "Mode: Preserved existing georeferencing"
fi
echo ""
if [ "$METADATA_SUCCESS" = true ]; then
  echo "This COG is ready for TiTiler display!"
else
  echo "⚠️  WARNING: COG created but may be difficult to locate in viewer without metadata."
fi
echo ""
