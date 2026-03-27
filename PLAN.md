# DeepTime MVP Implementation Plan

**Status**: In Progress  
**Last Updated**: 2026-03-24  
**Timeline**: 2-3 weeks

---

## 📋 Project Overview

**DeepTime MVP**: Cloud-based photomosaic browsing and AI-assisted annotation system for coral disease tracking.

**Goal**: Validate the COG → TiTiler → CVAT pipeline with a single test dataset while optimizing costs through dual-tier architecture.

**Partnership**: STINAPA Bonaire - Coral disease tracking (SCTLD)  
**Dataset**: 3TB coral photogrammetry, 34,057 m² across 18 sites

---

## 🏗️ Architecture

```
GCS Bucket (COG files)
    ↓
TiTiler on Cloud Run (serverless tile server)
    ↓
    ├──→ CVAT Browse Server (24/7, no GPU) - Data exploration
    │    └──→ PostgreSQL (shared database)
    │             ↑
    └──→ CVAT + SAM Server (on-demand, GPU) ──┘
                AI annotation (uses remote DB)
```

### GCP Services Used

1. **Google Cloud Storage** - Host COG files
2. **Cloud Run** - Serverless TiTiler tile server
3. **Compute Engine VM #1** - Browse server (e2-medium, 24/7) + shared PostgreSQL
4. **Compute Engine VM #2** - Annotation server (n1-standard-8 + L4 GPU, on-demand)
5. **Cloud IAM** - Service accounts and permissions
6. **VPC** - Default VPC with firewall rules

---

## 💰 Cost Estimate

- **GCS**: $0.06/month (3GB)
- **TiTiler**: $0-5/month (mostly free tier)
- **Browse Server**: $28/month (e2-medium, 24/7) + shared PostgreSQL
- **GPU Server**: $240/month (8hrs/day, 20 days)
- **Total**: ~$273/month (73% savings vs 24/7 GPU approach)

**Note**: E2-medium shared-core machine type reduces Browse server costs by 72% compared to N2-standard-2, while maintaining sufficient resources (4GB RAM, 2 vCPU) for CVAT browsing workload.

---

## ✅ Success Criteria

- [ ] TiTiler serves tiles from GCS bucket
- [ ] Browse server accessible 24/7 at `http://[ip]:8080`
- [ ] Imagery streams smoothly with pan/zoom
- [ ] GPU server shows GPU via `nvidia-smi`
- [ ] SAM 3 segmentation works (<5 seconds per object)
- [ ] GPU VM can be manually stopped when not in use
- [ ] Complete setup documentation exists

---

## 📦 Deliverables

✅ Single COG file hosted in GCS and served via TiTiler  
✅ 24/7 CVAT browse server for exploring coral imagery  
✅ On-demand GPU server for SAM 3-assisted annotation  
✅ Manual deployment scripts via gcloud CLI  
✅ Complete documentation

---

## 🎯 Features & Tasks

### Epic #1: DeepTime MVP - COG Browsing + On-Demand AI Annotation

> Main tracking issue for the entire MVP project

---

### Feature #2: GCP Project Setup

**Status**: ⬜ Not Started  
**Estimated Effort**: 2-3 hours  
**GitHub Issue**: [#2](https://github.com/kidconcept/deeptime/issues/2)

Set up the Google Cloud Platform project with required APIs, service accounts, and network configuration.

#### Tasks

- [ ] **#3** - Enable required GCP APIs
  - Enable Compute Engine, Cloud Run, Cloud Storage APIs
  - Verify with `gcloud services list --enabled`
  
- [ ] **#4** - Set up billing alerts
  - Create alerts at $100, $200, $400 thresholds
  - Configure email notifications
  
- [ ] **#5** - Create service accounts and IAM roles
  - Create `titiler-sa` service account
  - Grant Storage Object Viewer role
  
- [ ] **#6** - Configure VPC firewall rules
  - Allow port 8080 for CVAT access
  - Create rules for browse and annotate servers

#### Acceptance Criteria

- [ ] `gcloud services list --enabled` shows required APIs
- [ ] Service account exists with correct permissions
- [ ] Firewall rules allow access to port 8080
- [ ] Billing alerts configured and verified

---

### Feature #7: Storage + TiTiler Deployment

**Status**: ⬜ Not Started  
**Estimated Effort**: 4-6 hours  
**GitHub Issue**: [#7](https://github.com/kidconcept/deeptime/issues/7)

Set up Google Cloud Storage bucket, prepare and upload COG file, and deploy TiTiler serverless tile server.

#### Tasks

- [ ] **#8** - Create GCS bucket
  - Bucket in `us-central1` region
  - Grant TiTiler service account access
  
- [ ] **#9** - Select and convert image to COG format
  - Install GDAL: `brew install gdal`
  - Convert using: `gdal_translate -of COG -co COMPRESS=JPEG -co QUALITY=85 ...`
  - Validate: `rio cogeo validate file.tif`
  
- [ ] **#10** - Upload COG to GCS bucket
  - Upload: `gcloud storage cp file.tif gs://bucket/`
  - Document GCS URI
  
- [ ] **#11** - Deploy TiTiler to Cloud Run
  - Deploy: `gcloud run deploy titiler --image=ghcr.io/developmentseed/titiler:latest`
  - Configure service account and memory limits
  
- [ ] **#12** - Test TiTiler tile serving
  - Test info endpoint: `/cog/info?url=gs://...`
  - Test tile endpoint: `/cog/tiles/{z}/{x}/{y}.png?url=gs://...`
  - Verify tiles load in <1 second

#### Acceptance Criteria

- [ ] GCS bucket exists and is accessible
- [ ] COG file passes validation: `rio cogeo validate file.tif`
- [ ] TiTiler service running on Cloud Run
- [ ] Tile endpoint returns valid PNG images

---

### Feature #13: Browse Server (24/7)

**Status**: ⬜ Not Started  
**Estimated Effort**: 6-8 hours  
**GitHub Issue**: [#13](https://github.com/kidconcept/deeptime/issues/13)

Deploy always-on CVAT server for browsing coral imagery, without GPU acceleration. This server will also host the shared PostgreSQL database used by both Browse and Annotation servers.

#### Tasks

- [ ] **#14** - Create Browse VM
  - Machine type: e2-medium (2 vCPU, 4 GB RAM, shared-core)
  - Reserve static IP address
  - Create VM with Ubuntu 22.04 LTS
  
- [ ] **#15** - Install Docker and Docker Compose on Browse VM
  - Install Docker: `curl -fsSL https://get.docker.com | sh`
  - Install Docker Compose plugin
  - Verify: `docker run hello-world`
  
- [ ] **#16** - Configure CVAT docker-compose for browse-only
  - Create docker-compose.yml with core CVAT components
  - Exclude GPU/serverless components
  - Configure postgres, redis, server, workers, UI
  
- [ ] **#17** - Deploy CVAT stack on Browse VM
  - Start containers: `docker compose up -d`
  - Create superuser account
  - Verify all containers running
  
- [ ] **#18** - Import COG via TiTiler into CVAT
  - Create project for coral annotation
  - Add labels: healthy_coral, diseased_coral, sctld_lesion, etc.
  - Import imagery and verify browsability

#### Acceptance Criteria

- [ ] CVAT accessible at `http://[browse-ip]:8080`
- [ ] Can pan/zoom through coral imagery smoothly
- [ ] Multiple users can log in simultaneously
- [ ] Manual annotations work (polygons, labels)
- [ ] VM set to always-on (no auto-shutdown)

---

### Feature #37: Annotation Server (On-Demand GPU)

**Status**: ⬜ Not Started  
**Estimated Effort**: 8-10 hours  
**GitHub Issue**: [#37](https://github.com/kidconcept/deeptime/issues/37)

Deploy GPU-powered CVAT server with SAM 3 for AI-assisted annotation, designed to run on-demand only.

#### Tasks

- [ ] **#38** - Create GPU VM for Annotation Server
  - Machine type: n1-standard-8 + NVIDIA L4 GPU
  - Configure auto-install for NVIDIA drivers
  - Note: Costs ~$1.50/hour when running
  
- [ ] **#39** - Install NVIDIA drivers and Docker with GPU support
  - Install NVIDIA Container Toolkit
  - Configure Docker GPU runtime
  - Verify: `docker run --gpus all nvidia/cuda:12.0.0-base nvidia-smi`
  
- [ ] **#40** - Configure CVAT docker-compose with serverless/SAM
  - Add `cvat_serverless` container with GPU support
  - Configure GPU device reservations
  - Set up SAM 3 model
  
- [ ] **#41** - Deploy CVAT with GPU support
  - Start containers with GPU access
  - Verify GPU visible: `docker exec cvat_serverless nvidia-smi`
  - Create admin user
  
- [ ] **#42** - Test SAM 3 auto-segmentation
  - Test interactive segmentation on coral features
  - Verify <5 second response time
  - Monitor GPU utilization

#### Acceptance Criteria

- [ ] CVAT accessible at `http://[annotate-ip]:8080`
- [ ] GPU visible in container: `nvidia-smi`
- [ ] SAM 3 available in annotation tools
- [ ] Auto-segmentation completes in <5 seconds
- [ ] Can manually start/stop VM to control costs

**Cost Note**: Running costs ~$1.50/hour. Stopped costs ~$0.50/month (disk only).

---

### Feature #43: Integration Testing & Documentation

**Status**: ⬜ Not Started  
**Estimated Effort**: 4-6 hours  
**GitHub Issue**: [#43](https://github.com/kidconcept/deeptime/issues/43)

Validate the complete pipeline end-to-end and create comprehensive documentation for MVP deployment and usage.

#### Tasks

- [ ] **#44** - End-to-end integration testing
  - Test complete workflow: Browse → Annotate → Export
  - Verify data integrity across transitions
  - Document performance metrics
  
- [ ] **#45** - Create startup/shutdown scripts for cost management
  - `start-annotate-server.sh` - Start GPU VM
  - `stop-annotate-server.sh` - Stop GPU VM
  - `check-server-status.sh` - Show status of all components
  
- [ ] **#46** - Write MVP deployment documentation
  - Step-by-step setup guide
  - Architecture documentation
  - Troubleshooting guide
  
- [ ] **#47** - Create user guide for researchers
  - Daily workflow documentation
  - Annotation best practices
  - Export procedures
  
- [ ] **#48** - Document costs and optimization strategies
  - Cost breakdown per component
  - Cost-saving tips
  - Usage monitoring

#### Acceptance Criteria

- [ ] Complete workflow tested and documented
- [ ] Scripts enable easy VM management
- [ ] Documentation clear enough for new users
- [ ] All success criteria from Epic met
- [ ] Team ready to begin Phase 2 planning

---

## 📝 Implementation Notes

### Key Decisions

1. **Dual-tier architecture** (browse + annotate) chosen for 60% cost savings vs 24/7 GPU
2. **Manual deployment** via gcloud CLI (no Terraform/IaC for MVP)
3. **Single test dataset** for validation before scaling
4. **L4 GPU** selected for SAM 3 (cost-effective for inference)

### Prerequisites

- Google Cloud account with billing enabled
- `gcloud` CLI installed and configured
- `gh` CLI for issue tracking
- Docker knowledge for troubleshooting
- At least one coral imagery file for testing

### Helpful Commands

```bash
# Check server status
./scripts/check-server-status.sh

# Start annotation server (GPU)
./scripts/start-annotate-server.sh

# Stop annotation server (save costs!)
./scripts/stop-annotate-server.sh

# Create all GitHub issues
./scripts/create-github-issues.sh

# List all issues
gh issue list --repo kidconcept/deeptime --limit 50
```

---

## 🔄 Progress Tracking

**Last Status Check**: 2026-03-24

| Feature | Status | Issues Created | Issues Completed |
|---------|--------|----------------|------------------|
| GCP Project Setup (#2) | ⬜ Not Started | 1 + 4 tasks | 0/5 |
| Storage + TiTiler (#7) | ⬜ Not Started | 1 + 5 tasks | 0/6 |
| Browse Server (#13) | ⬜ Not Started | 1 + 5 tasks | 0/6 |
| Annotation Server (#37) | ⬜ Not Started | 1 + 5 tasks | 0/6 |
| Testing & Docs (#43) | ⬜ Not Started | 1 + 5 tasks | 0/6 |

**Total Progress**: 0/28 tasks completed

---

## 🚀 Next Steps

1. ✅ Complete issue creation (all 28 issues created)
2. ✅ Remove duplicate issues (#19-36 closed)
3. ⬜ Begin Phase 1: GCP Project Setup (#2)
4. ⬜ Track progress by closing issues as tasks complete
5. ⬜ Update this plan weekly

---

## 📚 Reference Links

- [GitHub Issues](https://github.com/kidconcept/deeptime/issues)
- [GitHub Epic #1](https://github.com/kidconcept/deeptime/issues/1)
- [Create Issues Script](scripts/create-github-issues.sh)
- [Session Plan](/.well-known/memories/session/plan.md) (in session memory)

---

## 🐛 Known Issues

_None yet - MVP not started_

---

## 💡 Future Enhancements (Post-MVP)

- Terraform/IaC for infrastructure as code
- Automated VM scheduling (start/stop on schedule)
- Direct TiTiler integration with CVAT (custom plugin)
- Multi-COG support
- User authentication via Cloud IAP
- Cost monitoring dashboard
- Automated backup procedures
