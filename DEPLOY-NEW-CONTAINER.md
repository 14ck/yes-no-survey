# Deployment Guide: New Proxmox Container

This guide covers deploying the Yes/No Survey app to a **new dedicated Proxmox LXC container** using Docker.

## Overview

This deployment creates a fresh LXC container specifically for the survey application with:
- **Container ID**: 401 (customizable)
- **Hostname**: yes-no-survey
- **OS**: Ubuntu 22.04 LXC
- **Resources**: 2GB RAM, 2 CPU cores, 8GB storage
- **Docker**: Automatically installed
- **Application Port**: 3000

## Prerequisites

- Proxmox host access (SSH)
- Ubuntu 22.04 LXC template available on Proxmox
- Project files accessible from Windows machine
- Network access from Windows to Proxmox host

## Quick Deployment

### Step 1: Prepare Project Files (Windows Machine)

From your project directory in Git Bash, WSL, or PowerShell:

```bash
cd C:\Bitbucket\yes-no-survey

# Create archive excluding build artifacts
tar --exclude='node_modules' --exclude='build' --exclude='.svelte-kit' -czf yes-no-survey.tar.gz .
```

**Alternative** if you don't have tar on Windows:
- Use 7-Zip or WinRAR to create a `.tar.gz` archive
- Exclude: `node_modules`, `build`, `.svelte-kit` folders

### Step 2: Transfer Files to Proxmox

```bash
# Transfer project archive
scp yes-no-survey.tar.gz root@YOUR-PROXMOX-IP:/tmp/

# Transfer deployment script
scp deploy-new-container.sh root@YOUR-PROXMOX-IP:/tmp/
```

Replace `YOUR-PROXMOX-IP` with your actual Proxmox host IP address.

### Step 3: Run Automated Deployment (Proxmox Host)

```bash
# SSH to Proxmox
ssh root@YOUR-PROXMOX-IP

# Make script executable
chmod +x /tmp/deploy-new-container.sh

# Run deployment with default container ID (401)
/tmp/deploy-new-container.sh

# Or specify a custom container ID
/tmp/deploy-new-container.sh 402
```

The script will automatically:
1. Create new LXC container
2. Install Docker and Docker Compose
3. Deploy your application
4. Display access URL

### Step 4: Access Your Application

After deployment completes, the script will display:

```
Access the app at: http://CONTAINER-IP:3000
```

Open this URL in your browser to use the survey application.

## Manual Deployment (Step-by-Step)

If you prefer manual control or the script fails, follow these detailed steps:

### 1. Create LXC Container

```bash
# SSH to Proxmox host
ssh root@YOUR-PROXMOX-IP

# Create container (ID 401)
pct create 401 local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
  --hostname yes-no-survey \
  --memory 2048 \
  --cores 2 \
  --net0 name=eth0,bridge=vmbr0,ip=dhcp \
  --storage local-lvm \
  --rootfs local-lvm:8 \
  --unprivileged 0 \
  --features nesting=1

# Start the container
pct start 401

# Wait for boot
sleep 5
```

**Parameters Explained:**
- `401`: Container ID (change if needed)
- `--hostname yes-no-survey`: Container hostname
- `--memory 2048`: 2GB RAM
- `--cores 2`: 2 CPU cores
- `--net0`: Network interface with DHCP
- `--rootfs local-lvm:8`: 8GB root filesystem
- `--unprivileged 0`: Run as privileged (required for Docker)
- `--features nesting=1`: Enable nesting for Docker

### 2. Install Docker

```bash
# Update system
pct exec 401 -- bash -c "apt update && apt upgrade -y"

# Install prerequisites
pct exec 401 -- bash -c "apt install -y ca-certificates curl gnupg lsb-release"

# Add Docker GPG key
pct exec 401 -- bash -c "install -m 0755 -d /etc/apt/keyrings"
pct exec 401 -- bash -c "curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg"
pct exec 401 -- bash -c "chmod a+r /etc/apt/keyrings/docker.gpg"

# Add Docker repository
pct exec 401 -- bash -c 'echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null'

# Install Docker
pct exec 401 -- bash -c "apt update"
pct exec 401 -- bash -c "apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin"

# Verify installation
pct exec 401 -- docker --version
pct exec 401 -- docker compose version
```

### 3. Deploy Application

```bash
# Create deployment directory
pct exec 401 -- mkdir -p /opt/yes-no-survey

# Copy project archive to container
pct push 401 /tmp/yes-no-survey.tar.gz /tmp/yes-no-survey.tar.gz

# Extract files
pct exec 401 -- tar -xzf /tmp/yes-no-survey.tar.gz -C /opt/yes-no-survey

# Cleanup archive
pct exec 401 -- rm /tmp/yes-no-survey.tar.gz

# Build and start Docker container
pct exec 401 -- bash -c "cd /opt/yes-no-survey && docker compose up -d --build"
```

### 4. Verify Deployment

```bash
# Check Docker container status
pct exec 401 -- docker ps

# Should show:
# CONTAINER ID   IMAGE              COMMAND        STATUS         PORTS                    NAMES
# xxxxx          yes-no-survey...   "node build"   Up X seconds   0.0.0.0:3000->3000/tcp   yes-no-survey

# Get container IP
pct exec 401 -- hostname -I

# Test application
curl http://CONTAINER-IP:3000

# View logs
pct exec 401 -- docker logs yes-no-survey -f
```

## Container Management

### Basic Container Operations

```bash
# Start container
pct start 401

# Stop container
pct stop 401

# Restart container
pct restart 401

# Enter container shell
pct enter 401

# Check container status
pct status 401

# View container configuration
pct config 401
```

### Application Management

```bash
# View application logs
pct exec 401 -- docker logs yes-no-survey -f

# Restart application
pct exec 401 -- bash -c "cd /opt/yes-no-survey && docker compose restart"

# Stop application
pct exec 401 -- bash -c "cd /opt/yes-no-survey && docker compose down"

# Start application
pct exec 401 -- bash -c "cd /opt/yes-no-survey && docker compose up -d"

# Rebuild application (after code changes)
pct exec 401 -- bash -c "cd /opt/yes-no-survey && docker compose up -d --build"

# View Docker containers in LXC
pct exec 401 -- docker ps

# Check Docker logs
pct exec 401 -- docker logs yes-no-survey --tail 100
```

## Updating the Application

### Method 1: Update Files and Rebuild

```bash
# From Windows: Create new archive with updated code
cd C:\Bitbucket\yes-no-survey
tar --exclude='node_modules' --exclude='build' --exclude='.svelte-kit' -czf yes-no-survey-updated.tar.gz .

# Transfer to Proxmox
scp yes-no-survey-updated.tar.gz root@YOUR-PROXMOX-IP:/tmp/

# On Proxmox: Deploy updated files
pct exec 401 -- bash -c "cd /opt/yes-no-survey && docker compose down"
pct push 401 /tmp/yes-no-survey-updated.tar.gz /tmp/yes-no-survey.tar.gz
pct exec 401 -- tar -xzf /tmp/yes-no-survey.tar.gz -C /opt/yes-no-survey
pct exec 401 -- rm /tmp/yes-no-survey.tar.gz
pct exec 401 -- bash -c "cd /opt/yes-no-survey && docker compose up -d --build"
```

### Method 2: Update Individual Files

```bash
# Copy specific file to container
pct push 401 /path/to/updated/file.svelte /opt/yes-no-survey/src/routes/file.svelte

# Rebuild
pct exec 401 -- bash -c "cd /opt/yes-no-survey && docker compose up -d --build"
```

## Configuration

### Change Application Port

If port 3000 is already in use or you want a different port:

1. Edit `docker-compose.yml` before deployment:
   ```yaml
   ports:
     - "3001:3000"  # Change 3001 to your desired external port
   ```

2. Or modify in the running container:
   ```bash
   pct exec 401 -- bash -c "cd /opt/yes-no-survey && docker compose down"
   # Edit docker-compose.yml
   pct exec 401 -- bash -c "cd /opt/yes-no-survey && docker compose up -d"
   ```

### Adjust Container Resources

```bash
# Change RAM (2GB to 4GB)
pct set 401 --memory 4096

# Change CPU cores (2 to 4)
pct set 401 --cores 4

# Changes take effect after container restart
pct restart 401
```

### Enable Container Auto-Start

```bash
# Start container automatically on Proxmox boot
pct set 401 --onboot 1
```

## Networking Setup

### Access Via Custom Domain

#### Option 1: Using Pi-hole DNS + Nginx Proxy Manager

**1. Add DNS Record in Pi-hole**
- Access Pi-hole admin: `http://YOUR-PIHOLE-IP/admin`
- Navigate to: Local DNS → DNS Records
- Add record:
  - Domain: `survey.local`
  - IP: Container IP or Nginx Proxy Manager IP

**2. Configure Nginx Proxy Manager**
- Access NPM: `http://NPM-IP:81`
- Add Proxy Host:
  - Domain Names: `survey.local`
  - Scheme: `http`
  - Forward Hostname/IP: `CONTAINER-IP`
  - Forward Port: `3000`
  - Enable "Block Common Exploits"
  - Enable "Websockets Support" (if needed)

**3. Access Application**
- URL: `http://survey.local`
- Or with SSL: `https://survey.local`

#### Option 2: Port Forward from Proxmox Host

```bash
# On Proxmox host, add iptables rule
iptables -t nat -A PREROUTING -i vmbr0 -p tcp --dport 3000 -j DNAT --to CONTAINER-IP:3000

# Make persistent
apt install iptables-persistent
netfilter-persistent save
```

Access via: `http://PROXMOX-IP:3000`

## Troubleshooting

### Container Creation Fails

**Error: Template not found**

```bash
# List available templates
pveam available | grep ubuntu

# Download Ubuntu 22.04 template
pveam download local ubuntu-22.04-standard_22.04-1_amd64.tar.zst

# Wait for download to complete
pveam list local
```

**Error: Container ID already exists**

```bash
# Choose a different ID
/tmp/deploy-new-container.sh 402

# Or remove existing container
pct stop 401
pct destroy 401
```

### Docker Installation Fails

```bash
# Enter container manually
pct enter 401

# Check network connectivity
ping -c 3 google.com

# Check DNS resolution
cat /etc/resolv.conf

# If DNS issues, set Google DNS temporarily
echo "nameserver 8.8.8.8" > /etc/resolv.conf

# Retry Docker installation
exit
# Re-run deployment script
```

### Application Won't Start

```bash
# Check Docker daemon status
pct exec 401 -- systemctl status docker

# If not running, start Docker
pct exec 401 -- systemctl start docker

# Check for errors in logs
pct exec 401 -- docker logs yes-no-survey

# Common issues:
# - Port 3000 already in use
# - Build failures (missing dependencies)
# - Permission issues
```

### Port Already in Use

```bash
# Check what's using port 3000
pct exec 401 -- netstat -tlnp | grep 3000
# or
pct exec 401 -- ss -tlnp | grep 3000

# Change port in docker-compose.yml to 3001
pct exec 401 -- bash -c "cd /opt/yes-no-survey && docker compose down"
# Edit docker-compose.yml
pct exec 401 -- bash -c "cd /opt/yes-no-survey && docker compose up -d"
```

### Can't Access Application

```bash
# 1. Verify container is running
pct status 401

# 2. Verify Docker container is running
pct exec 401 -- docker ps | grep yes-no-survey

# 3. Get container IP
CONTAINER_IP=$(pct exec 401 -- hostname -I | awk '{print $1}')
echo $CONTAINER_IP

# 4. Test from Proxmox host
curl http://$CONTAINER_IP:3000

# 5. Check firewall in container
pct exec 401 -- ufw status

# If UFW is active, allow port 3000
pct exec 401 -- ufw allow 3000

# 6. Check if application is listening
pct exec 401 -- netstat -tlnp | grep 3000
```

### Build Errors

```bash
# View full build logs
pct exec 401 -- docker logs yes-no-survey

# Common issues:
# - Node.js version mismatch (should use Node 20)
# - Missing dependencies in package.json
# - TypeScript compilation errors

# Rebuild with no cache
pct exec 401 -- bash -c "cd /opt/yes-no-survey && docker compose build --no-cache"
pct exec 401 -- bash -c "cd /opt/yes-no-survey && docker compose up -d"
```

## Backup and Restore

### Backup Container

```bash
# Create backup of entire container
vzdump 401 --mode stop --storage local

# Backup to specific location
vzdump 401 --mode snapshot --storage local --dumpdir /backup

# Backup just the application data
pct exec 401 -- tar -czf /tmp/survey-backup.tar.gz -C /opt/yes-no-survey .
pct pull 401 /tmp/survey-backup.tar.gz /backup/survey-backup-$(date +%Y%m%d).tar.gz
```

### Restore Container

```bash
# Restore from Proxmox backup
pct restore 401 /var/lib/vz/dump/vzdump-lxc-401-*.tar

# Or restore just application files
pct push 401 /backup/survey-backup.tar.gz /tmp/survey-backup.tar.gz
pct exec 401 -- tar -xzf /tmp/survey-backup.tar.gz -C /opt/yes-no-survey
pct exec 401 -- bash -c "cd /opt/yes-no-survey && docker compose up -d --build"
```

## Complete Removal

To completely remove the container and application:

```bash
# Stop and remove Docker containers
pct exec 401 -- bash -c "cd /opt/yes-no-survey && docker compose down"

# Remove Docker images (optional, to free space)
pct exec 401 -- docker image prune -a -f

# Stop LXC container
pct stop 401

# Destroy LXC container (THIS DELETES EVERYTHING)
pct destroy 401

# Cleanup Proxmox host
rm -f /tmp/yes-no-survey.tar.gz
rm -f /tmp/deploy-new-container.sh
```

## Performance Tuning

### Increase Container Resources

For better performance with multiple concurrent users:

```bash
# Increase RAM to 4GB
pct set 401 --memory 4096

# Increase CPU cores to 4
pct set 401 --cores 4

# Restart container
pct restart 401
```

### Docker Resource Limits

Edit `docker-compose.yml` to add resource limits:

```yaml
services:
  yes-no-survey:
    build: .
    container_name: yes-no-survey
    restart: unless-stopped
    ports:
      - "3000:3000"
    environment:
      - NODE_ENV=production
      - PORT=3000
    deploy:
      resources:
        limits:
          cpus: '2.0'
          memory: 1G
        reservations:
          cpus: '1.0'
          memory: 512M
```

## Security Considerations

### Firewall Configuration

```bash
# Install and enable UFW in container
pct exec 401 -- apt install -y ufw

# Allow only port 3000
pct exec 401 -- ufw default deny incoming
pct exec 401 -- ufw default allow outgoing
pct exec 401 -- ufw allow 3000
pct exec 401 -- ufw enable
```

### Network Isolation

The container is on the same network as Proxmox host by default. For better isolation:

```bash
# Create isolated network on Proxmox
# This requires advanced Proxmox networking setup
# See Proxmox documentation for VLAN configuration
```

### Keep System Updated

```bash
# Update container OS
pct exec 401 -- apt update && pct exec 401 -- apt upgrade -y

# Update Docker
pct exec 401 -- apt update && pct exec 401 -- apt install --only-upgrade docker-ce docker-ce-cli containerd.io
```

## Monitoring

### View Resource Usage

```bash
# Container resource usage
pct status 401 --verbose

# Docker container stats
pct exec 401 -- docker stats yes-no-survey --no-stream

# Disk usage
pct exec 401 -- df -h
pct exec 401 -- docker system df
```

### Application Health Check

```bash
# Simple HTTP health check
curl -f http://CONTAINER-IP:3000 || echo "App is down"

# Check response time
time curl -s http://CONTAINER-IP:3000 > /dev/null
```

## Additional Resources

- **Proxmox Documentation**: https://pve.proxmox.com/wiki/Linux_Container
- **Docker Documentation**: https://docs.docker.com/
- **SvelteKit Documentation**: https://kit.svelte.dev/docs
- **Project README**: See `README.md` in project root
- **Alternative Deployment**: See `DEPLOY.md` for deploying to existing container 400

## Quick Reference

### Essential Commands

```bash
# Container management
pct start 401                    # Start container
pct stop 401                     # Stop container
pct enter 401                    # Enter container shell

# Application management
pct exec 401 -- docker ps        # List Docker containers
pct exec 401 -- docker logs yes-no-survey -f  # View logs

# Access application
http://CONTAINER-IP:3000         # Direct access

# Update application
# 1. Transfer new archive to /tmp/yes-no-survey.tar.gz
# 2. Run: pct exec 401 -- bash -c "cd /opt/yes-no-survey && docker compose down"
# 3. Run: pct exec 401 -- tar -xzf /tmp/yes-no-survey.tar.gz -C /opt/yes-no-survey
# 4. Run: pct exec 401 -- bash -c "cd /opt/yes-no-survey && docker compose up -d --build"
```

## Support

For issues or questions:
- Check the troubleshooting section above
- Review Docker logs: `pct exec 401 -- docker logs yes-no-survey`
- Review application README.md for app-specific details
- Check Proxmox system logs: `journalctl -xe`
