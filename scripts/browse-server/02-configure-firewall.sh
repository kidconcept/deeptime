#!/bin/bash
PROJECT_ID=$(gcloud config get-value project)
BUCKET_NAME="deeptime-cogs-${PROJECT_ID}"
COG_FILE="/Volumes/Mojarra/Bonaire Baseline/Scans/18th Palm North/2023-09-27/COG/18palms.tif"

# Extract just the filename
FILENAME=$(basename "$COG_FILE")

# Upload to GCS
gcloud storage cp "$COG_FILE" gs://${BUCKET_NAME}/

# Verify upload - list the specific file
gcloud storage ls "gs://${BUCKET_NAME}/${FILENAME}"

# Get GCS URI for TiTiler
GCS_URI="gs://${BUCKET_NAME}/${FILENAME}"
echo "COG uploaded to: $GCS_URI"

# Save to .env for later use
echo "COG_GCS_URI=${GCS_URI}" >> ../.env