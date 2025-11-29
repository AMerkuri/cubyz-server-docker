#!/bin/bash
set -e

# Configuration
REGISTRY="ghcr.io"
IMAGE_NAME="${GITHUB_REPOSITORY:-username/cubyz-server}"  # Override with your repo
TAG="${1:-latest}"
PLATFORMS="linux/amd64,linux/arm64"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}=== Building and pushing multi-arch image ===${NC}"
echo "Registry: ${REGISTRY}"
echo "Image: ${IMAGE_NAME}"
echo "Tag: ${TAG}"
echo "Platforms: ${PLATFORMS}"
echo ""

# Check if logged in to GHCR
if ! echo "$GITHUB_TOKEN" | docker login ${REGISTRY} -u ${GITHUB_ACTOR:-username} --password-stdin 2>/dev/null; then
    echo -e "${YELLOW}Warning: Not logged in to GHCR. Please set GITHUB_TOKEN and GITHUB_ACTOR${NC}"
    echo -e "${YELLOW}Example: export GITHUB_TOKEN=your_token && export GITHUB_ACTOR=your_username${NC}"
    exit 1
fi

# Create builder if it doesn't exist
if ! docker buildx inspect multiarch-builder > /dev/null 2>&1; then
    echo -e "${GREEN}Creating buildx builder...${NC}"
    docker buildx create --name multiarch-builder --use
    docker buildx inspect --bootstrap
else
    echo -e "${GREEN}Using existing buildx builder...${NC}"
    docker buildx use multiarch-builder
fi

# Build and push
echo -e "${GREEN}Building and pushing images...${NC}"
docker buildx build \
    --platform ${PLATFORMS} \
    --tag ${REGISTRY}/${IMAGE_NAME}:${TAG} \
    --tag ${REGISTRY}/${IMAGE_NAME}:latest \
    --no-cache \
    --push \
    .

echo -e "${GREEN}=== Build and push completed successfully! ===${NC}"
echo -e "Image: ${REGISTRY}/${IMAGE_NAME}:${TAG}"
echo -e "Platforms: ${PLATFORMS}"
