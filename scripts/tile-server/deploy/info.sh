#!/bin/bash
# Show TiTiler service information

# Get script directory and repo root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Load environment variables from repo root
source "$REPO_ROOT/.env" 2>/dev/null || true

PROJECT_ID=${PROJECT_ID:-$(gcloud config get-value project)}
SERVICE_NAME="titiler"
REGION=${REGION:-"us-central1"}

echo "========================================="
echo "TiTiler Service Information"
echo "========================================="
echo ""

# Get service details
gcloud run services describe $SERVICE_NAME \
  --region=$REGION \
  --format="table(
    metadata.name,
    status.url,
    status.conditions[0].status,
    spec.template.spec.serviceAccountName,
    spec.template.spec.containers[0].resources.limits.memory,
    spec.template.spec.containers[0].resources.limits.cpu
  )"

echo ""
echo "Environment Variables:"
gcloud run services describe $SERVICE_NAME \
  --region=$REGION \
  --format="value(spec.template.spec.containers[0].env)"

echo ""
echo "Service URL:"
gcloud run services describe $SERVICE_NAME \
  --region=$REGION \
  --format="value(status.url)"
