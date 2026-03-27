INPUT_FILE="/Volumes/Mojarra/Bonaire Baseline/Scans/18th Palm North/2023-09-27/GIS/18palms.vrt"
OUTPUT_FILE="/Volumes/Mojarra/Bonaire Baseline/Scans/18th Palm North/2023-09-27/COG/18palms.tif"

# Convert to COG with appropriate settings for coral imagery
gdal_translate \
  -of COG \
  -co COMPRESS=JPEG \
  -co QUALITY=85 \
  -co BLOCKSIZE=512 \
  -co OVERVIEWS=AUTO \
  -co RESAMPLING=BILINEAR \
  "$INPUT_FILE" \
  "$OUTPUT_FILE"

# Validate
rio cogeo validate "$OUTPUT_FILE"