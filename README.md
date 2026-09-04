# deeptime

A vibe coded tool for browsing and annotating large photomosaic datasets. 

---

---

## Project Overview

Accelerating Coral Disease Tracking via AI-Assisted Photogrammetry

**Background**: Partnering with STINAPA Bonaire, we collected 3TB of high-resolution coral photogrammetry (34,057 m² across 18 sites) during the 2023 Stony Coral Tissue Loss Disease (SCTLD) outbreak and are soon to collect an additional 8 comparison sites this year. Historically, analyzing such massive datasets was hindered by rendering and transfer latency for distributed teams. Today, advances in AI-assisted coding enable us to build a scalable, cloud-native environment that translates raw data into actionable conservation metrics. At least, we'll see. Don't run this code on your own without care.

---

## Summary

### What We've Built

- **TiTiler tile server** — Serverless tile server deployed on GCP Cloud Run, serving Cloud Optimized GeoTIFF (COG) coral imagery directly from a GCS bucket.
- **Browse server** — A lightweight Node.js + Leaflet web app running 24/7 on a GCP e2-medium VM. Lets distributed teams pan, zoom, and explore large coral photomosaics in the browser with no data transfer overhead.
- **COG pipeline** — Scripts to convert raw photogrammetry to COG format, upload to GCS, and register new datasets with the viewer.
- **Deployment tooling** — Shell scripts for provisioning, deploying, starting/stopping, and SSH-ing into both the tile and browse servers via gcloud.

### What We're Planning to Build

Annotation server — A single on-demand GPU server (GCE n1-standard-4 + NVIDIA T4 for dev, upgradeable to L4) that runs both the browse app and a SAM 3 inference API (Python/FastAPI). Users click coral heads in the Leaflet map, SAM 3 returns pixel-accurate segmentation masks, and an interactive refine cycle (positive/negative clicks) lets users adjust boundaries before accepting. Annotations are stored as Instance COGs — single-band uint16 rasters where each pixel value identifies an individual coral — paired with a metadata table mapping instance IDs to coral species, annotator, and other attributes. TiTiler serves the label COGs as colored overlays on the map. The server runs on-demand (~$0.18/hr spot, ~$0.54/hr on-demand) and is stopped when not in use.