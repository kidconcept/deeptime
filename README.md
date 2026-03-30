# deeptime

A tool for browsing and annotating large photomosaic datasets

---

## Getting Started

### Prerequisites

- Google Cloud SDK (`gcloud`) installed and authenticated
- Node.js 16+ (for browse server and scripts)
- Access to Google Cloud project with billing enabled

### Environment Setup

1. **Copy environment template**:
   ```bash
   cp .env.example .env
   ```

2. **Configure your environment** - Edit `.env` with your project details:
   ```bash
   PROJECT_ID=your-project-id
   REGION=us-central1
   BUCKET_NAME=your-bucket-name
   ```

3. **Deploy TiTiler** (automatically updates `TITILER_URL` in `.env`):
   ```bash
   bash scripts/tile-server/deploy/deploy.sh
   ```

4. **Verify configuration**:
   ```bash
   source .env
   echo $TITILER_URL
   bash scripts/tile-server/deploy/test.sh
   ```

All scripts and applications read from this centralized `.env` file. See individual deployment guides for more details:
- [TILE-SERVER.md](TILE-SERVER.md) - TiTiler deployment and COG management
- [BROWSE-SERVER.md](BROWSE-SERVER.md) - Browse server deployment and configuration

---

## Project Overview

Accelerating Coral Disease Tracking via AI-Assisted Photogrammetry

**Background**: Partnering with STINAPA Bonaire, we collected 3TB of high-resolution coral photogrammetry (34,057 m² across 18 sites) during the 2023 Stony Coral Tissue Loss Disease (SCTLD) outbreak and are soon to collect an additional 8 comparison sites this year. Historically, analyzing such massive datasets was hindered by rendering and transfer latency for distributed teams. Today, advances in AI-assisted coding enable us to build a scalable, cloud-native environment that translates raw data into actionable conservation metrics.

**Proposed Solution**: We will implement an AI-assisted pipeline for high-performance streaming and rapid annotation. By centralizing data in Google Cloud Storage (GCS), we will use Cloud Optimized GeoTIFFs (COGs) and a serverless TiTiler engine to stream imagery into a Dockerized CVAT environment on Google Compute Engine with NVIDIA L4 GPUs.

**Implementation Milestones**:
Phase 1: Infrastructure (Months 1–3): Deploy GCS, TiTiler on Cloud Run, and CVAT, enabling seamless global data browsing for distributed researchers.
Phase 2: Annotation (Months 4–6): Utilize CVAT’s integrated SAM 3 agent for high-fidelity coral tagging, establishing a "Gold Standard" dataset and launching the open-access tool's trial.
Phase 3: Consolidation (Months 7–9): Unify masks into an ecological database and leverage Vertex AI for automated batch-classification against the baseline.
Phase 4: Publishing (Months 10–12): Share final reef health statistics to guide STINAPA managers and extend the tool for broader benthic ecosystem monitoring.