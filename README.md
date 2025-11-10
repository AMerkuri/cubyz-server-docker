# Cubyz Server Docker

Docker container for running Cubyz headless server with multi-architecture support (amd64/arm64).

## Quick Start

### Using Docker CLI

```bash
docker run -d \
  --network host \
  -v cubyz-saves:/cubyz/saves \
  -e CUBYZ_WORLD_NAME=myworld \
  ghcr.io/amerkuri/cubyz-server-docker:latest
```

### Using Docker Compose

Create a `compose.yml` file:

```yaml
services:
  cubyz:
    image: ghcr.io/amerkuri/cubyz-server-docker:latest
    network_mode: host
    volumes:
      - ./saves:/cubyz/saves
    environment:
      - CUBYZ_WORLD_NAME=myworld
    restart: unless-stopped
```

> **Note**: For a full `compose.yml` example with auto-heal and health checks, see [`compose.yml`](https://github.com/AMerkuri/cubyz-server-docker/blob/main/compose.yml).

Then run:

```bash
# Start server
docker compose up -d

# View logs
docker compose logs -f

# Stop server
docker compose down
```

## Configuration

### Environment Variables

- `CUBYZ_WORLD_NAME` - World name (default: `world`)

### Build Arguments

You can customize the build process using these arguments:

- `GIT_REPO` - Cubyz repository URL (default: `https://github.com/PixelGuys/Cubyz`)
- `GIT_BRANCH` - Git branch to build from (default: `master`)
- `USER_UID` - User ID for the cubyz user (default: `1000`)
- `USER_GID` - Group ID for the cubyz group (default: `1000`)

Example with custom build args:

```bash
docker build \
  --build-arg GIT_REPO=https://github.com/your-fork/Cubyz.git \
  --build-arg GIT_BRANCH=custom-branch \
  --build-arg USER_UID=100 \
  --build-arg USER_GID=101 \
  -t cubyz-server:custom \
  .
```

Or in `compose.yml`:

```yaml
services:
  cubyz:
    build:
      context: .
      args:
        - GIT_REPO=https://github.com/your-fork/Cubyz.git
        - GIT_BRANCH=custom-branch
        - USER_UID=1001
        - USER_GID=1001
```

### Volumes

- `/cubyz/saves` - Persistent world data

### Ports

- `47649/udp` - Game server port

## Building Locally

```bash
# Build for your architecture
npm run build

# Or with Docker Compose
docker compose build --no-cache

# Build multi-arch manually
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t cubyz-server:local \
  .
```

## Troubleshooting

- **Container exited with code 137**  
    This may indicate insufficient memory. Monitor memory usage and consider allocating more resources.

- **Failed to create world: FileNotFound**  
    Ensure the volume for saves is correctly mounted, existing world is present at `saves/world` and has appropriate permissions.

- **Unknown connection from address: 192.168.x.x:30287**
    Use host networking mode in Docker to avoid NAT issues