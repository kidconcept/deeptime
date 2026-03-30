# Tile Server Deployment Guide

**Feature #7**: TiTiler on Cloud Run  
**Purpose**: Serverless tile server for streaming Cloud Optimized GeoTIFFs (COGs) from Google Cloud Storage as web map tiles.

This guide provides all the necessary steps to deploy, manage, and monitor the TiTiler service on Google Cloud Run.

---

## Quick Start

**Prerequisites**:
- Google Cloud SDK (`gcloud`) installed and authenticated
- Service account `titiler-sa` exists with Storage Object Viewer role
- COG files uploaded to GCS bucket

### 1. Deploy TiTiler

To deploy the TiTiler service to Cloud Run:

```bash
bash scripts/tile-server/deploy/deploy.sh
```

This command will:
1. Deploy TiTiler container from GitHub Container Registry
2. Configure memory (2Gi), CPU (2 cores), and timeout (300s)
3. Attach the `titiler-sa` service account for GCS access
4. Set GDAL environment variables for performance optimization
5. Test the deployment with health checks

The service will be available at the URL shown after deployment.

### 2. Test the Deployment

```bash
bash scripts/tile-server/deploy/test.sh
```

---

## Scripts

### Deployment Scripts

Deployment scripts are located in `scripts/tile-server/deploy/`:

- **`deploy.sh`**: Main deployment script with full configuration
- **`test.sh`**: Validates TiTiler endpoints and GCS access
- **`setup-sa.sh`**: Creates and configures the service account
- **`info.sh`**: Shows service configuration and status

### COG Management Utility

The `cog` utility provides a unified CLI for managing Cloud Optimized GeoTIFFs. Located at `scripts/tile-server/cog`.

#### Commands

**List COGs in bucket**:
```bash
bash scripts/tile-server/cog list
```

**Inspect a COG** (shows GCS metadata, georeferencing, TiTiler compatibility):
```bash
bash scripts/tile-server/cog inspect <filename.tif>
```

**Upload a COG** to GCS bucket:
```bash
bash scripts/tile-server/cog upload <local-file.tif> [remote-name.tif]
```

**Remove a COG** from bucket (with confirmation):
```bash
bash scripts/tile-server/cog remove <filename.tif>
```

**Create an optimized COG** with georeferencing:
```bash
bash scripts/tile-server/cog create [OPTIONS] <input> [output] [site_name]

Options:
  -a, --arbitrary    Add arbitrary (0,0) georeferencing for non-georeferenced files
  -h, --help         Show help message

Examples:
  # Single georeferenced file
  bash scripts/tile-server/cog create scan.tif output.tif
  
  # Directory of tiles with arbitrary georeferencing
  bash scripts/tile-server/cog create --arbitrary GIS/tiles/ output-georef.tif site1
```

The `create` command:
- Builds VRT from directories of tiles
- Applies georeferencing (preserves existing or adds arbitrary at 0,0)
- Calculates optimal Web Mercator zoom levels
- Generates COG with JPEG compression and overviews
- Validates output compatibility with TiTiler

Management scripts are in `scripts/tile-server/manage/`:
- `create.sh` - Create optimized COGs with georeferencing
- `list.sh` - List bucket contents
- `upload.sh` - Upload with validation
- `inspect.sh` - Detailed file inspection
- `remove.sh` - Safe deletion with confirmation

---

## Service Configuration

**Service Name**: `titiler`  
**Platform**: Cloud Run (fully managed, serverless)  
**Region**: us-central1  
**Container Image**: `ghcr.io/developmentseed/titiler:latest`  
**Service Account**: `titiler-sa@deeptime-491316.iam.gserviceaccount.com`  
**URL**: See `.env` file for current URL (set by `deploy.sh`)

### Resource Configuration

- **Memory**: 2Gi (adequate for large COG processing)
- **CPU**: 2 cores (better tile generation performance)
- **Timeout**: 300 seconds (5 minutes for complex operations)
- **Max Instances**: 10 (auto-scaling)
- **Min Instances**: 0 (scales to zero when idle)
- **Port**: 8000 (container port)

### Environment Variables

GDAL optimization settings for GCS performance:

```bash
GDAL_DISABLE_READDIR_ON_OPEN=EMPTY_DIR
CPL_VSIL_CURL_ALLOWED_EXTENSIONS=.tif
GDAL_HTTP_MERGE_CONSECUTIVE_RANGES=YES
GDAL_HTTP_MULTIPLEX=YES
GDAL_HTTP_VERSION=2
```

### IAM Configuration

- **Authentication**: Unauthenticated (public access)
- **Service Account Permission**: `roles/storage.objectViewer` on GCS bucket

---

## Access

**Service URL**:
```bash
# Set from your .env file
TITILER_URL=<value from .env>

# Or source the .env file
source .env
echo $TITILER_URL
```

**API Documentation**:
```bash
# Load environment first
source .env

# View TiTiler API docs
open "${TITILER_URL}/docs"
```

---

## API Endpoints

**Note**: All examples below use `$TITILER_URL` and `$COG_GCS_URI` variables. Set these first:
```bash
source .env  # Load environment variables from repo root
```

### Information Endpoints

**COG Info** - Returns metadata about a COG file:
```bash
curl "${TITILER_URL}/cog/info?url=${COG_GCS_URI}"
```

**COG Statistics** - Returns band statistics:
```bash
curl "${TITILER_URL}/cog/statistics?url=${COG_GCS_URI}"
```

### Image Endpoints

**Preview** - Full image at reduced resolution:
```bash
curl "${TITILER_URL}/cog/preview.png?url=${COG_GCS_URI}&max_size=1024" \
  --output preview.png
```

**Tiles** - Web Mercator tiles (requires georeferenced COG):
```bash
curl "${TITILER_URL}/cog/tiles/WebMercatorQuad/{z}/{x}/{y}.png?url=${COG_GCS_URI}"
```

**Part** - Specific pixel region (works without georeferencing):
```bash
curl "${TITILER_URL}/cog/part.png?url=${COG_GCS_URI}&bbox=0,0,5000,5000" \
  --output part.png
```

### Available TileMatrixSets

```bash
curl "${TITILER_URL}/tileMatrixSets"
```

---

## Monitoring

**View Service Details**:
```bash
gcloud run services describe titiler --region=us-central1
```

**View Logs**:
```bash
gcloud run services logs read titiler --region=us-central1 --limit=50
```

**Quick Status Check**:
```bash
bash scripts/tile-server/deploy/info.sh
```

**View Metrics** (via Cloud Console):
- Request count
- Request latency
- Container instance count
- Memory/CPU utilization

---

## Cost Estimate

**Cloud Run Pricing**:
- First 2 million requests/month: FREE
- CPU: $0.00002400 per vCPU-second
- Memory: $0.00000250 per GiB-second
- Network egress: First 1 GB free, then $0.12/GB

**Typical Monthly Cost**:
- Light usage (< 100k requests): $0-5
- Moderate usage (500k requests): $10-20
- Heavy usage (2M+ requests): $30-50

**Cost Optimization**:
- Serverless: Only pay when processing requests
- Auto-scales to zero when idle
- No minimum charges when not in use

---

## Deployment Commands

### View Current Configuration

```bash
bash scripts/tile-server/deploy/info.sh
```

Or manually:
```bash
gcloud run services describe titiler \
  --region=us-central1 \
  --format='value(spec.template.spec.serviceAccountName,spec.template.spec.containers[0].resources.limits.memory,spec.template.spec.containers[0].env)'
```

### Update Service (if needed)

```bash
# Update memory
gcloud run services update titiler \
  --region=us-central1 \
  --memory=4Gi

# Update environment variables
gcloud run services update titiler \
  --region=us-central1 \
  --set-env-vars="NEW_VAR=value"
```

### Redeploy (same configuration)

```bash
bash scripts/tile-server/deploy/deploy.sh
```

---

## Troubleshooting

### Issue: Tiles return corrupted images

**Cause**: COG lacks proper georeferencing  
**Solution**: Add georeferencing to COG (see `scripts/cog/` for georeferencing tools)

**Workaround**: Use `/cog/preview` or `/cog/part` endpoints which don't require georeferencing

### Issue: "Access Denied" errors

**Cause**: Service account lacks GCS permissions  
**Solution**:
```bash
bash scripts/tile-server/deploy/setup-sa.sh deeptime-491316
```

Or manually:
```bash
gcloud projects add-iam-policy-binding deeptime-491316 \
  --member="serviceAccount:titiler-sa@deeptime-491316.iam.gserviceaccount.com" \
  --role="roles/storage.objectViewer"
```

### Issue: Slow tile generation

**Diagnosis**: Check COG optimization  
```bash
rio cogeo validate gs://deeptime-cogs-deeptime-491316/18palms.tif
```

**Solutions**:
- Ensure COG has internal tiling (512x512 blocks)
- Ensure COG has overviews (pyramids)
- Increase Cloud Run memory if needed

### Issue: Timeout errors

**Cause**: Complex operations exceeding 300s timeout  
**Solution**: Increase timeout (max 3600s for Cloud Run):
```bash
gcloud run services update titiler \
  --region=us-central1 \
  --timeout=600
```

---

## Status

- [x] **Task #11**: TiTiler deployed to Cloud Run
- [x] Service account configured with Storage Object Viewer role
- [x] Memory and CPU optimized (2Gi, 2 cores)
- [x] GDAL environment variables configured
- [x] Info endpoint working
- [x] Preview endpoint working
- [ ] Tile endpoint (blocked by COG georeferencing - see Task #9)

## Service Status

**Service is LIVE**: ✅ Running on Cloud Run  
**URL**: Check `.env` file or run `bash scripts/tile-server/deploy/info.sh`  
**Container**: ghcr.io/developmentseed/titiler:latest  
**Auto-scaling**: 0-10 instances

**Health Checks**:
```bash
# Quick test (requires .env configured)
bash scripts/tile-server/deploy/test.sh

# Manual tests
source .env
curl -s "${TITILER_URL}/cog/info?url=${COG_GCS_URI}" | head -5
curl -s "${TITILER_URL}/cog/preview.png?url=${COG_GCS_URI}&max_size=512" -o test.png
```

---

## Redeployment After Grant Credits

When you receive Google Cloud credits and need to redeploy in a new project:

### Quick Redeployment

**1. Prepare New Project**

```bash
# Set new project
gcloud config set project NEW-PROJECT-ID

# Enable required APIs
gcloud services enable run.googleapis.com storage.googleapis.com
```

**2. Create Service Account**

```bash
bash scripts/tile-server/deploy/setup-sa.sh NEW-PROJECT-ID
```

**3. Upload COGs to New Bucket**

```bash
# Create bucket
gcloud storage buckets create gs://NEW-BUCKET-NAME --location=us-central1

# Upload COGs using cog utility
bash scripts/tile-server/cog upload /path/to/file.tif

# Or upload multiple files
for f in /path/to/cogs/*.tif; do
  bash scripts/tile-server/cog upload "$f"
done
```

**4. Update Configuration**

```bash
# Update .env with new values (in repo root)
cat > .env << EOF
PROJECT_ID=NEW-PROJECT-ID
REGION=us-central1
BUCKET_NAME=NEW-BUCKET-NAME
COG_GCS_URI=gs://NEW-BUCKET-NAME/your-test-file.tif
TITILER_SA_EMAIL=titiler-sa@NEW-PROJECT-ID.iam.gserviceaccount.com
EOF
```

**5. Deploy TiTiler**

```bash
bash scripts/tile-server/deploy/deploy.sh
```

**6. Test New Deployment**

```bash
bash scripts/tile-server/deploy/test.sh
```

**Total redeployment time**: ~15 minutes

---

## Related Documentation

- [BROWSE-SERVER.md](BROWSE-SERVER.md) - Leaflet viewer that consumes TiTiler tiles
- [PLAN.md](PLAN.md) - Overall project plan and architecture
- [GitHub Issue #11](https://github.com/kidconcept/deeptime/issues/11) - TiTiler deployment tracking

---

## References

- **TiTiler Documentation**: https://developmentseed.org/titiler/
- **TiTiler GitHub**: https://github.com/developmentseed/titiler
- **Cloud Run Documentation**: https://cloud.google.com/run/docs
- **COG Specification**: https://www.cogeo.org/
