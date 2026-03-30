# Browse Server Deployment Guide

**Feature #13**: Browse Server (24/7)  
**Purpose**: A lightweight Node.js server with a Leaflet-based viewer for browsing large Cloud Optimized GeoTIFFs (COGs) of coral imagery via a TiTiler service.

This guide provides all the necessary steps to deploy, manage, and update the Browse Server infrastructure on Google Cloud.

---

## Quick Start

### First-Time Setup (New Environment)

1. **Configure deployment settings**:
```bash
cd scripts/browse-server
cp .deploy-config.example .deploy-config
# Edit .deploy-config with your environment details
```

2. **Provision the server** (creates VM, installs dependencies, deploys app):
```bash
./provision.sh
```

The server will be available at the IP address specified in your config (e.g., `http://34.61.65.156:8081`).

### Deploying Code Updates

After making changes to the browse-server code:
```bash
cd scripts/browse-server
./deploy.sh
```

This copies your latest code and restarts the application (~30 seconds).

---

## Available Commands

| Command | Purpose | When to Use |
|---------|---------|-------------|
| `./provision.sh` | Full setup from scratch | First deployment to new environment |
| `./deploy.sh` | Update application code | Every time you make code changes |
| `./start.sh` | Start the VM | After stopping VM to save costs |
| `./stop.sh` | Stop the VM | To save costs when not in use |
| `./logs.sh` | View application logs | Debugging, monitoring |
| `./ssh.sh` | SSH into the VM | Manual server management |

---

## Configuration

### Deployment Configuration

Edit `.deploy-config` (created from `.deploy-config.example`) to set:

```bash
VM_NAME="browse-server"              # VM instance name
ZONE="us-central1-a"                 # GCP zone
VM_STATIC_IP="34.61.65.156"          # Reserved static IP
PORT="8081"                          # Application port
MACHINE_TYPE="e2-micro"              # VM size
DISK_SIZE="20GB"                     # Boot disk size
IMAGE_FAMILY="ubuntu-2204-lts"       # OS image
IMAGE_PROJECT="ubuntu-os-cloud"      # Image source project
NETWORK_TAG="browse-server"          # Network tag for firewall
APP_DIR="/var/www/leaflet-viewer"    # Application directory on VM
```

**Note**: `.deploy-config` is gitignored. Never commit credentials or environment-specific values.

### Environment Variables

The browse server reads configuration from a `.env` file in the repository root. This file is automatically copied to the VM during deployment.

**Required variables**:
```bash
TITILER_URL=https://titiler-xxxxx-uc.a.run.app  # TiTiler service URL (set by deploy.sh)
```

**Setup**:
1. Copy the example file: `cp .env.example .env`
2. Deploy TiTiler first: `bash scripts/tile-server/deploy/deploy.sh` (auto-updates `.env`)
3. Deploy browse server: `cd scripts/browse-server && ./deploy.sh` (copies `.env` to VM)

The server will use fallback URLs if `.env` is missing, but for production use, always configure `.env` properly.

### Multiple Environments

For staging/production environments:

```bash
cp .deploy-config.example .deploy-config-production
cp .deploy-config.example .deploy-config-staging

# Edit each with appropriate values
# Then deploy:
./provision.sh --config=.deploy-config-production
./deploy.sh --config=.deploy-config-staging
```

---

## Architecture

### Deployment Phases

**Phase 1: Infrastructure** (one-time)
- Create GCE VM instance
- Reserve and assign static IP
- Configure firewall rules

**Phase 2: Environment Setup** (one-time per VM)
- Install Node.js runtime
- Install PM2 process manager
- Create application directory
- Set permissions

**Phase 3: Application Deployment** (repeatable)
- Copy application code
- Install npm dependencies
- Start/restart application with PM2
- Configure PM2 auto-start on boot

### Script Organization

```
scripts/browse-server/
├── .deploy-config.example    # Configuration template
├── .deploy-config            # Your config (gitignored)
│
├── provision.sh              # Full setup (phases 1+2+3)
├── deploy.sh                 # Code updates (phase 3 only)
├── start.sh                  # Start stopped VM
├── stop.sh                   # Stop running VM
├── logs.sh                   # View PM2 logs
├── ssh.sh                    # SSH to VM
│
└── _lib/                     # Internal scripts (don't run directly)
    ├── create-vm.sh          # Phase 1: Infrastructure
    ├── setup-environment.sh  # Phase 2: Node.js/PM2
    └── deploy-app.sh         # Phase 3: Application
```

---

## Detailed Usage

### Initial Provisioning

Creates everything from scratch:

```bash
./provision.sh
```

**What it does**:
1. Checks if VM exists, creates if needed
2. Reserves static IP if not already reserved
3. Configures firewall rule for your port
4. Installs Node.js v20 and PM2
5. Deploys application code
6. Starts application with PM2
7. Configures PM2 to auto-start on boot

**Time**: ~5-10 minutes (mostly VM creation and package installation)

### Deploying Updates

Updates only the application code:

```bash
./deploy.sh
```

**What it does**:
1. Ensures VM is running
2. Copies browse-server code to VM
3. Stops old PM2 process
4. Installs/updates npm dependencies
5. Starts new PM2 process
6. Saves PM2 configuration

**Time**: ~30-60 seconds

### Managing VM Lifecycle

**Stop VM** (saves money on compute):
```bash
./stop.sh
```
You'll still be charged for static IP and disk storage, but not CPU/RAM.

**Start VM** (after stopping):
```bash
./start.sh
```
Waits for VM to boot (~30 seconds), then shows status.

**View logs** (real-time):
```bash
./logs.sh
```
Shows PM2 logs with auto-follow. Press Ctrl+C to exit.

**SSH into VM**:
```bash
./ssh.sh
```

---

## Troubleshooting

### Deployment fails with "could not parse resource"

**Issue**: Environment variables not loaded.

**Solution**: Make sure `.deploy-config` exists and contains valid settings:
```bash
cat .deploy-config  # Verify contents
```

### Application won't start

**Check logs**:
```bash
./logs.sh
```

**SSH in and check PM2**:
```bash
./ssh.sh
pm2 list            # See all processes
pm2 logs            # View logs
pm2 restart leaflet-viewer  # Restart app
```

### Firewall blocking access

Verify firewall rule:
```bash
gcloud compute firewall-rules describe allow-browse-server
```

### VM not responding

Check VM status:
```bash
gcloud compute instances describe browse-server --zone=us-central1-a
```

Restart VM:
```bash
./stop.sh && ./start.sh
```

---

## Cost Management

**Active costs** (VM running):
- e2-micro VM: ~$6-7/month
- 20GB standard disk: ~$0.80/month
- Static IP (in use): Free

**Stopped costs** (VM stopped):
- Static IP (reserved): ~$3/month
- 20GB standard disk: ~$0.80/month

**Total monthly cost**: 
- Running 24/7: ~$8/month
- Stopped: ~$4/month

**To minimize costs**: Run `./stop.sh` when not actively using the server.

---

## Security Notes

- SSH access uses Google Cloud's identity-aware proxy
- The application runs as non-root user
- Firewall only allows ingress on configured port
- PM2 manages process isolation and auto-restart
- Use `.deploy-config` (gitignored) for sensitive values

---

## Access Information

**SSH Access**:
```bash
./ssh.sh
# Or directly:
gcloud compute ssh browse-server --zone=us-central1-a
```

**Web Access**:
```
http://<YOUR_STATIC_IP>:<PORT>
```

Example: `http://34.61.65.156:8081`

---

## Maintenance

### Updating Node.js/PM2

SSH into the VM and update:
```bash
./ssh.sh
sudo npm install -g pm2@latest
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### Restarting Application

```bash
./ssh.sh
pm2 restart leaflet-viewer
```

Or redeploy:
```bash
./deploy.sh
```

### Cleaning Up Old Deployments

```bash
./ssh.sh
pm2 delete leaflet-viewer
sudo rm -rf /var/www/leaflet-viewer
```

Then re-provision:
```bash
./provision.sh
```

---

## Application Details

### Local Structure
```
browse-server/
├── package.json          # Express dependency
├── server.js            # Express server with tile proxying
└── public/
    ├── index.html       # Main page with Leaflet
    ├── styles.css       # Tray-based UI styling
    ├── cogs.json        # COG metadata
    └── js/
        ├── app.js                      # Application initialization
        ├── cog-data-manager.js         # COG metadata handling
        ├── map-controller.js           # Leaflet map & zoom config
        ├── tools/
        │   └── coordinates-tool.js     # Click map to show lat/lon
        └── ui/
            ├── cog-selector.js         # COG selection UI
            ├── message-bus.js          # Status messages
            ├── map-info.js             # COG metadata display
            └── tool-manager.js         # Tool activation system
```

### UI Structure

The application uses a **tray-based layout** with four main sections:

1. **COG Selector** (`#cog-selector`) - Dropdown to switch between COG files
2. **Map Info** (`#map-info`) - Current COG metadata (name, bounds, zoom levels)
3. **Tools** (`#tools`) - Interactive map tools with icon buttons
   - Coordinates tool: Click map to display lat/lon
4. **Messages** (`#messages`) - Status updates and system messages

**Loading Behavior**: Map initializes empty, COG tiles load first, then satellite layer loads after first tile arrives. This prevents bandwidth usage during TiTiler cold starts.

### Remote Deployment
- **Directory**: `/var/www/leaflet-viewer/`
- **Process Manager**: PM2 (auto-restart on crash, auto-start on boot)
- **Port**: 8081 (configurable via `.deploy-config`)

### Features
- **Delayed Loading**: Satellite tiles only load after TiTiler responds (prevents wasted bandwidth on cold starts)
- **Satellite Background**: Esri World Imagery with server-side CORS proxy
- **COG Tiles**: TiTiler integration for Cloud Optimized GeoTIFFs
- **Layer Priority**: COG data renders above satellite (zIndex: 1000 vs 0)
- **Zoom Range**: 3-28 (satellite capped at native zoom 18, then scaled)
- **Interactive Tools**: Extensible tool system with coordinates display
- **Status Messages**: Real-time feedback in tray message panel

---

## Current Status

**Server**: ✅ Live at http://34.61.65.156:8081  
**Deployment Scripts**: ✅ Fully refactored and documented  
**Features**: ✅ Satellite map background, robust zoom, COG loading

### Recent Updates
- Restructured UI into tray-based layout with four sections
- Added Tools section with extensible tool system
- Implemented coordinates tool (click map to show lat/lon)
- Added delayed loading to prevent satellite bandwidth usage during TiTiler cold starts
- Renamed metadata panel to map-info for clarity
- Simplified all container IDs (removed "-container" suffixes)
- Added icon button UI for tools with visual active states
- Implemented message panel for real-time status updates

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
