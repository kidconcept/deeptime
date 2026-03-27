# Browse Server Deployment Guide

**Feature #13**: Browse Server (24/7)  
**Purpose**: A lightweight Node.js server with a Leaflet-based viewer for browsing large Cloud Optimized GeoTIFFs (COGs) of coral imagery via a TiTiler service.

This guide provides all the necessary steps to deploy, manage, and shut down the Browse Server infrastructure on Google Cloud.

---

## Quick Start

**Prerequisites**:
- Google Cloud SDK (`gcloud`) installed and authenticated.
- `gsutil` and `gcloud compute` components are available.

### 1. Deploy the Server

To create the VM, configure the firewall, and deploy the application, run the master deployment script:

```bash
bash scripts/deploy-browse-server.sh
```

This command will:
1.  **Start the VM** if it's stopped.
2.  **Create the VM** and reserve a static IP if it doesn't exist.
3.  **Configure firewall rules** to allow traffic on port 8081.
4.  **Install Node.js and PM2** on the VM.
5.  **Deploy the application**, install dependencies, and start it with PM2.

The server will be available at `http://34.61.65.156:8081`.

### 2. Stop the Server (to Save Costs)

To stop the VM and prevent charges for CPU and RAM, run:

```bash
bash scripts/stop-browse-server.sh
```

This will shut down the VM instance. You will still be billed for the static IP and the boot disk storage.

---

## Deployment Scripts

The deployment process is managed by a set of scripts located in the `scripts/` directory.

- **`deploy-browse-server.sh`**: The main script that orchestrates the entire deployment. It calls the other scripts in order.
- **`stop-browse-server.sh`**: Stops the VM to save costs.
- **`browse-server/`**: A directory containing the individual, numbered steps of the deployment:
    - `01-create-vm.sh`: Creates the GCE instance and reserves the static IP.
    - `02-configure-firewall.sh`: Creates the firewall rule.
    - `03-setup-node.sh`: Installs Node.js and PM2.
    - `04-deploy-app.sh`: Deploys the Node.js application and starts it with PM2.
- **`utils.sh`**: Contains shared helper functions used by the deployment scripts.

---

## VM Configuration

**VM Name**: `browse-server`  
**Static IP**: `34.61.65.156`  
**Machine Type**: e2-micro (2 vCPU, 1 GB RAM, shared-core)  
**OS**: Ubuntu 22.04 LTS  
**Boot Disk**: 20 GB standard persistent disk  
**Region/Zone**: us-central1 / us-central1-a  
**Network Tag**: `browse-server`

---

## Access

**SSH Access**:
```bash
gcloud compute ssh browse-server --zone=us-central1-a
```

**Web Access** (after deployment):
```
http://34.61.65.156:8081
```

---

## Deployment Scripts

### VM Creation
```bash
./scripts/browse-vm-create.sh
```

Creates the VM instance with static IP reservation.

### Node.js Setup
```bash
./scripts/browse-setup.sh
```

Installs Node.js 20.x, npm, and PM2 process manager.

### Application Deployment
```bash
./scripts/browse-deploy.sh
```

Deploys the Leaflet viewer application to `/var/www/leaflet-viewer/` on the VM.

### Firewall Configuration
```bash
./scripts/browse-firewall.sh
```

Opens port 8081 for public web access.

**Firewall Rule**: `allow-browse-server`
- Port: TCP 8081
- Direction: INGRESS
- Source: 0.0.0.0/0 (public)
- Target: VMs with tag `browse-server`
- Status: Active

---

## Cost Estimate

- **VM**: e2-micro = ~$7/month (24/7)
- **Static IP**: ~$3/month when attached to running VM
- **Network egress**: Minimal (<$1/month)
- **Total**: ~$11/month

**Savings**: 88% cost reduction vs e2-medium CVAT browse server

---

## Software Versions

- **Node.js**: v20.20.0 (LTS)
- **npm**: 10.8.2
- **PM2**: 6.0.14

---

## Application Structure

**Local directory**: `browse-server/`  
**Remote directory**: `/var/www/leaflet-viewer/`

```
browse-server/
├── package.json          # Express dependency
├── server.js            # Express static file server (port 8081)
└── public/
    ├── index.html       # Main page with Leaflet
    ├── viewer.js        # Map configuration & TiTiler integration
    └── styles.css       # Responsive dark theme
```

## Status

- [x] **Task #14**: VM created with static IP
- [x] **Task #15**: Node.js and npm installation
- [x] **Task #16**: Firewall rules configured
- [x] **Task #17**: Leaflet viewer deployed
- [x] **Task #18**: TiTiler COG integration (with non-georeferenced handling)
- [x] **Task #19**: PM2 service running (auto-start on boot pending)

## Server Status

**Server is LIVE**: ✅ Running on PM2  
**URL**: http://34.61.65.156:8081  
**Health Check**: http://34.61.65.156:8081/health

To check server status:
```bash
gcloud compute ssh browse-server --zone=us-central1-a --command="pm2 list"
```

To configure auto-start on boot:
```bash
gcloud compute ssh browse-server --zone=us-central1-a
pm2 startup
# Run the sudo command it provides
pm2 save
```
