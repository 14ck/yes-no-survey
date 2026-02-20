#!/bin/bash
# Automated deployment script for Yes/No Survey app
# Creates a new Proxmox LXC container and deploys the Docker application

set -e

# Configuration
CONTAINER_ID="${1:-401}"  # Default to 401, or use first argument
CONTAINER_NAME="yes-no-survey"
DEPLOY_PATH="/opt/${CONTAINER_NAME}"
PROJECT_ARCHIVE="/tmp/yes-no-survey.tar.gz"

echo "=========================================="
echo "Yes/No Survey - New Container Deployment"
echo "=========================================="
echo ""
echo "Container ID: ${CONTAINER_ID}"
echo "Container Name: ${CONTAINER_NAME}"
echo ""

# Step 1: Create LXC Container
echo "📦 Step 1: Creating LXC container..."
if pct status ${CONTAINER_ID} &>/dev/null; then
    echo "⚠️  Container ${CONTAINER_ID} already exists. Skipping creation."
else
    pct create ${CONTAINER_ID} local:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst \
        --hostname ${CONTAINER_NAME} \
        --memory 2048 \
        --cores 2 \
        --net0 name=eth0,bridge=vmbr0,ip=dhcp \
        --storage local-lvm \
        --rootfs local-lvm:8 \
        --unprivileged 0 \
        --features nesting=1
    echo "✅ Container ${CONTAINER_ID} created"
fi

# Step 2: Start Container
echo ""
echo "🚀 Step 2: Starting container..."
pct start ${CONTAINER_ID} || echo "Container already running"
sleep 5
echo "✅ Container started"

# Step 3: Install Docker
echo ""
echo "🐳 Step 3: Installing Docker..."
pct exec ${CONTAINER_ID} -- bash -c "
    if command -v docker &> /dev/null; then
        echo 'Docker already installed, skipping...'
    else
        echo 'Installing Docker...'
        apt update && apt upgrade -y
        apt install -y ca-certificates curl gnupg lsb-release

        install -m 0755 -d /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        chmod a+r /etc/apt/keyrings/docker.gpg

        echo \"deb [arch=\$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \$(lsb_release -cs) stable\" | tee /etc/apt/sources.list.d/docker.list > /dev/null

        apt update
        apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

        echo 'Docker installed successfully'
    fi
"
echo "✅ Docker installed"

# Step 4: Verify project archive exists
echo ""
echo "📁 Step 4: Checking for project files..."
if [ ! -f "${PROJECT_ARCHIVE}" ]; then
    echo "❌ Error: Project archive not found at ${PROJECT_ARCHIVE}"
    echo ""
    echo "Please transfer your project archive first:"
    echo "  scp yes-no-survey.tar.gz root@<proxmox-ip>:/tmp/"
    exit 1
fi
echo "✅ Project archive found"

# Step 5: Deploy application
echo ""
echo "📦 Step 5: Deploying application..."
pct exec ${CONTAINER_ID} -- mkdir -p ${DEPLOY_PATH}
pct exec ${CONTAINER_ID} -- mkdir -p /tmp

pct push ${CONTAINER_ID} ${PROJECT_ARCHIVE} /tmp/yes-no-survey.tar.gz
pct exec ${CONTAINER_ID} -- tar -xzf /tmp/yes-no-survey.tar.gz -C ${DEPLOY_PATH}
pct exec ${CONTAINER_ID} -- rm /tmp/yes-no-survey.tar.gz

echo "✅ Files copied to container"

# Step 6: Build and start Docker container
echo ""
echo "🔨 Step 6: Building and starting Docker container..."
pct exec ${CONTAINER_ID} -- bash -c "cd ${DEPLOY_PATH} && docker compose up -d --build"
echo "✅ Docker container started"

# Step 7: Get container IP and display access info
echo ""
echo "=========================================="
echo "✅ Deployment Complete!"
echo "=========================================="
echo ""

CONTAINER_IP=$(pct exec ${CONTAINER_ID} -- hostname -I | awk '{print $1}')
echo "🌐 Access the app at:"
echo "   http://${CONTAINER_IP}:3000"
echo ""
echo "📊 Useful commands:"
echo ""
echo "View logs:"
echo "  pct exec ${CONTAINER_ID} -- docker logs ${CONTAINER_NAME} -f"
echo ""
echo "Restart service:"
echo "  pct exec ${CONTAINER_ID} -- bash -c 'cd ${DEPLOY_PATH} && docker compose restart'"
echo ""
echo "Stop service:"
echo "  pct exec ${CONTAINER_ID} -- bash -c 'cd ${DEPLOY_PATH} && docker compose down'"
echo ""
echo "Enter container:"
echo "  pct enter ${CONTAINER_ID}"
echo ""
echo "Check Docker status:"
echo "  pct exec ${CONTAINER_ID} -- docker ps"
echo ""
echo "Container management:"
echo "  pct stop ${CONTAINER_ID}     # Stop container"
echo "  pct start ${CONTAINER_ID}    # Start container"
echo "  pct destroy ${CONTAINER_ID}  # Delete container"
echo ""
