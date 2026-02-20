# Deployment Guide: Container 400 (fileshare)

## Overview

This guide covers deploying the Yes/No Survey app to Container 400 (fileshare) on your Proxmox server.

**Container Info:**
- Container ID: 400
- Purpose: File Browser + Web Apps
- OS: Ubuntu LXC (privileged)
- Resources: 2GB RAM, 4 cores
- Existing Services: File Browser (port 8080), Pinchflat (port 8945)

## Prerequisites

- Proxmox host access (SSH)
- Container 400 running with Docker installed
- Project files on Proxmox host or accessible location

## Deployment Methods

### Method 1: Automated Script (Recommended)

From the Proxmox host, run the deployment script:

```bash
# Make script executable
chmod +x deploy-to-container-400.sh

# Run deployment
./deploy-to-container-400.sh
```

This will:
1. Create `/opt/yes-no-survey/` directory in the container
2. Copy all project files
3. Build and start the Docker container
4. Show access URL and management commands

### Method 2: Manual Deployment

#### Step 1: Copy Project to Container

From Proxmox host:

```bash
# Create directory
pct exec 400 -- mkdir -p /opt/yes-no-survey

# Option A: Copy entire directory if project is on Proxmox host
# (Replace /path/to/yes-no-survey with actual path)
pct push 400 /path/to/yes-no-survey /opt/yes-no-survey --recursive

# Option B: Transfer via SCP/rsync to Proxmox first, then push to container
```

#### Step 2: Build and Start

```bash
# Enter container
pct enter 400

# Navigate to project
cd /opt/yes-no-survey

# Build and start
docker compose up -d --build

# Exit container
exit
```

### Method 3: Deploy from Windows (Your Current Machine)

If you want to deploy directly from your Windows machine:

```bash
# 1. Create archive
cd yes-no-survey
tar -czf ../yes-no-survey.tar.gz .

# 2. Transfer to Proxmox host (adjust IP and path)
scp yes-no-survey.tar.gz root@10.0.0.69:/tmp/

# 3. SSH to Proxmox and deploy
ssh root@10.0.0.69

# 4. Extract to container
pct exec 400 -- mkdir -p /opt/yes-no-survey
pct push 400 /tmp/yes-no-survey.tar.gz /tmp/yes-no-survey.tar.gz
pct exec 400 -- tar -xzf /tmp/yes-no-survey.tar.gz -C /opt/yes-no-survey
pct exec 400 -- rm /tmp/yes-no-survey.tar.gz

# 5. Build and start
pct exec 400 -- bash -c "cd /opt/yes-no-survey && docker compose up -d --build"
```

## Access the Application

### Direct Access

Get the container IP:
```bash
pct exec 400 -- hostname -I
```

Access at: `http://<container-ip>:3000`

Example: `http://10.0.0.XXX:3000`

### Via Reverse Proxy (Recommended)

Set up a custom domain for easy access:

#### 1. Add DNS Record in Pi-hole

- Login to Pi-hole: `http://10.0.0.97/admin` or `http://100.112.234.115/admin`
- Go to: Local DNS → DNS Records
- Add new record:
  - Domain: `survey.local` (or your choice)
  - IP Address: `<container-400-ip>` or `10.0.0.97` (if using NPM on Pi)

#### 2. Configure Nginx Proxy Manager

- Login to NPM: `http://100.112.234.115:81`
- Add Proxy Host:
  - Domain Names: `survey.local`
  - Scheme: `http`
  - Forward Hostname/IP: `<container-400-ip>`
  - Forward Port: `3000`
  - ✅ Block Common Exploits
  - ✅ Websockets Support (if needed)

- (Optional) Add SSL:
  - SSL Certificate: Request new (Let's Encrypt) or use self-signed
  - ✅ Force SSL

Access at: `http://survey.local` or `https://survey.local`

## Management Commands

All commands run from Proxmox host:

### View Logs
```bash
pct exec 400 -- docker logs yes-no-survey -f
```

### Restart Service
```bash
pct exec 400 -- bash -c "cd /opt/yes-no-survey && docker compose restart"
```

### Stop Service
```bash
pct exec 400 -- bash -c "cd /opt/yes-no-survey && docker compose down"
```

### Start Service
```bash
pct exec 400 -- bash -c "cd /opt/yes-no-survey && docker compose up -d"
```

### Rebuild After Changes
```bash
pct exec 400 -- bash -c "cd /opt/yes-no-survey && docker compose up -d --build"
```

### Remove Service
```bash
pct exec 400 -- bash -c "cd /opt/yes-no-survey && docker compose down"
pct exec 400 -- rm -rf /opt/yes-no-survey
```

### Enter Container Shell
```bash
pct enter 400
# Then navigate to: cd /opt/yes-no-survey
```

### View Running Containers
```bash
pct exec 400 -- docker ps
```

## Verification

Check that the service is running:

```bash
# Check Docker container status
pct exec 400 -- docker ps | grep yes-no-survey

# Check if port 3000 is listening
pct exec 400 -- netstat -tlnp | grep 3000
# or
pct exec 400 -- ss -tlnp | grep 3000

# Test HTTP response
curl http://<container-ip>:3000
```

## Troubleshooting

### Container won't start

```bash
# Check logs
pct exec 400 -- docker logs yes-no-survey

# Check if port 3000 is already in use
pct exec 400 -- netstat -tlnp | grep 3000

# If port conflict, edit docker-compose.yml to use different port:
# Change "3000:3000" to "3001:3000" or another available port
```

### Can't access from browser

```bash
# Verify container is running
pct exec 400 -- docker ps | grep yes-no-survey

# Check container IP
pct exec 400 -- hostname -I

# Test from Proxmox host
curl http://<container-ip>:3000

# Check firewall (if UFW enabled in container)
pct exec 400 -- ufw status
```

### Need to update the app

```bash
# Copy updated files to container
pct push 400 /path/to/updated/file /opt/yes-no-survey/path/to/file

# Rebuild
pct exec 400 -- bash -c "cd /opt/yes-no-survey && docker compose up -d --build"
```

## Port Configuration

Current services on Container 400:
- **8080**: File Browser
- **8945**: Pinchflat
- **3000**: Yes/No Survey (new)

If you need to change the port, edit `docker-compose.yml`:

```yaml
ports:
  - "3001:3000"  # Change 3001 to your desired external port
```

## Next Steps

1. ✅ Deploy the application
2. ✅ Verify it's accessible
3. 🔧 Set up reverse proxy (optional but recommended)
4. 🔐 Consider adding authentication if needed
5. 💾 Add database for persistent storage (future enhancement)

## Notes

- Responses are currently stored in memory (lost on restart)
- For production use, consider adding a database
- The app is designed for internal network use
- Container 400 is on direct LAN (vmbr0), no port forwarding needed unless you want to access via Proxmox host IP
