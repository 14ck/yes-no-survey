#!/bin/bash
# Deployment script for Container 400 (fileshare)
# This script copies the project and deploys it to the container

set -e

CONTAINER_ID="400"
PROJECT_NAME="yes-no-survey"
DEPLOY_PATH="/opt/${PROJECT_NAME}"

echo "🚀 Deploying ${PROJECT_NAME} to Container ${CONTAINER_ID}..."

# Create deployment directory in container
echo "📁 Creating deployment directory..."
pct exec ${CONTAINER_ID} -- mkdir -p ${DEPLOY_PATH}

# Copy project files to container (exclude node_modules and build artifacts)
echo "📦 Copying project files..."
pct push ${CONTAINER_ID} package.json ${DEPLOY_PATH}/package.json
pct push ${CONTAINER_ID} svelte.config.js ${DEPLOY_PATH}/svelte.config.js
pct push ${CONTAINER_ID} vite.config.ts ${DEPLOY_PATH}/vite.config.ts
pct push ${CONTAINER_ID} tsconfig.json ${DEPLOY_PATH}/tsconfig.json
pct push ${CONTAINER_ID} tailwind.config.js ${DEPLOY_PATH}/tailwind.config.js
pct push ${CONTAINER_ID} postcss.config.js ${DEPLOY_PATH}/postcss.config.js
pct push ${CONTAINER_ID} Dockerfile ${DEPLOY_PATH}/Dockerfile
pct push ${CONTAINER_ID} docker-compose.yml ${DEPLOY_PATH}/docker-compose.yml
pct push ${CONTAINER_ID} .dockerignore ${DEPLOY_PATH}/.dockerignore

# Copy src directory recursively
echo "📂 Copying source files..."
pct exec ${CONTAINER_ID} -- mkdir -p ${DEPLOY_PATH}/src/routes
pct push ${CONTAINER_ID} src/app.html ${DEPLOY_PATH}/src/app.html
pct push ${CONTAINER_ID} src/app.css ${DEPLOY_PATH}/src/app.css
pct push ${CONTAINER_ID} src/app.d.ts ${DEPLOY_PATH}/src/app.d.ts
pct push ${CONTAINER_ID} src/routes/+layout.svelte ${DEPLOY_PATH}/src/routes/+layout.svelte
pct push ${CONTAINER_ID} src/routes/+page.svelte ${DEPLOY_PATH}/src/routes/+page.svelte

# Create static directory
pct exec ${CONTAINER_ID} -- mkdir -p ${DEPLOY_PATH}/static

# Build and start the application
echo "🔨 Building and starting Docker container..."
pct exec ${CONTAINER_ID} -- bash -c "cd ${DEPLOY_PATH} && docker compose up -d --build"

# Get container IP
CONTAINER_IP=$(pct exec ${CONTAINER_ID} -- hostname -I | awk '{print $1}')

echo ""
echo "✅ Deployment complete!"
echo ""
echo "🌐 Access the app at:"
echo "   http://${CONTAINER_IP}:3000"
echo ""
echo "📊 View logs:"
echo "   pct exec ${CONTAINER_ID} -- docker logs yes-no-survey -f"
echo ""
echo "🔄 Restart service:"
echo "   pct exec ${CONTAINER_ID} -- bash -c 'cd ${DEPLOY_PATH} && docker compose restart'"
echo ""
echo "🛑 Stop service:"
echo "   pct exec ${CONTAINER_ID} -- bash -c 'cd ${DEPLOY_PATH} && docker compose down'"
echo ""
