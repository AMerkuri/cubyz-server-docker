# Cubyz Server Docker

Docker container for running Cubyz headless server with multi-architecture support (amd64/arm64).

## Quick Start

### Using Docker CLI

```bash
docker run -d \
  -p 47649:47649/udp \
  -v ./saves:/cubyz/saves \
  -e CUBYZ_WORLD_NAME=world \
  ghcr.io/amerkuri/cubyz-server-docker:dev
```
> **Note**: Make sure mapped directory or volume `./saves` already contains existing world data `world`!

### Using Docker Compose

Create a `compose.yml` file:

```yaml
services:
  cubyz:
    image: ghcr.io/amerkuri/cubyz-server-docker:dev
    ports:
      - "47649:47649/udp"
    volumes:
      - ./saves:/cubyz/saves
    environment:
      - CUBYZ_WORLD_NAME=world
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

## Image Versioning

Docker image tags track upstream Cubyz releases published at <https://github.com/PixelGuys/Cubyz/tags>. Upstream tags use plain semantic versioning (`0.0.1`). For any upstream release, a multi-architecture image (`linux/amd64`, `linux/arm64`) is built and pushed:

- `X.Y.Z` – Exact version (e.g., `0.1.0`), built with `-Drelease=true`.
- `latest` – Most recent upstream release, built with `-Drelease=true`.
- `dev` – Latest upstream `master` branch, built **without** `-Drelease=true` (latest dev changes, syncs with upstream branch every hour).
- `main` – Built from this repository's `main` branch (internal, for CI/testing purposes only).

### Build Triggers

| Trigger | Upstream Ref | Release Build | Image Tags |
|---------|--------------|---------------|------------|
| Push to `main` branch | `master` | ✅ | `main` |
| Pull request to `main` | `master` | ✅ | `pr-X` |
| Tag push (e.g., `v1.0.0`) | `v1.0.0` | ✅ | `1.0.0`, `latest` |
| Upstream tag detected (polling) | `v1.0.0` | ✅ | `1.0.0`, `latest` |
| Upstream master changes (polling) | `master` | ❌ | `dev` |

#### Automatic Upstream Polling

A GitHub Actions workflow runs **every hour** to check for upstream changes:

1. **New tags** – Compares upstream [Cubyz tags](https://github.com/PixelGuys/Cubyz/tags) against existing GHCR image tags. Any missing version triggers a release build.

2. **Master branch commits** – Compares the latest upstream `master` commit SHA against the last built SHA. If different, triggers a `dev` build. The SHA is tracked via a `.last-dev-sha` file committed to this repository.

This ensures Docker images stay in sync with upstream.

### Picking a Tag

For stable deployments, pin an exact version (`X.Y.Z`). Use `latest` only when you intentionally want automatic upgrades. Use `dev` to test latest changes from upstream master (not recommended for production).

```bash
# Exact version (recommended for production)
docker run ghcr.io/amerkuri/cubyz-server-docker:0.1.0

# Latest released version
docker run ghcr.io/amerkuri/cubyz-server-docker:latest

# Development build (latest upstream master)
docker run ghcr.io/amerkuri/cubyz-server-docker:dev
```

Compose example with a pinned version:

```yaml
services:
  cubyz:
    image: ghcr.io/amerkuri/cubyz-server-docker:0.0.1
    network_mode: host
    volumes:
      - ./saves:/cubyz/saves
    environment:
      - CUBYZ_WORLD_NAME=world
    restart: unless-stopped
```

> **Note**: Image tag versions below `0.1.0` do not support headless server, therefore it will not run! Use `dev` tag instead.

### Upgrading

1. Review available tags ([GitHub packages UI](https://github.com/AMerkuri/cubyz-server-docker/pkgs/container/cubyz-server-docker) or: `crane ls ghcr.io/amerkuri/cubyz-server-docker`).
2. Update the tag in your deployment (e.g. bump `0.0.1` to `0.0.2`).
3. Pull & recreate containers:

```bash
docker pull ghcr.io/amerkuri/cubyz-server-docker:0.0.2
docker compose up -d --pull always --force-recreate
```

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

## Configuration

### Environment Variables

- `CUBYZ_WORLD_NAME` - World name (default: `world`)

### Build Arguments

You can customize the build process using these arguments:

- `GIT_REPO` - Cubyz repository URL (default: `https://github.com/PixelGuys/Cubyz`)
- `GIT_REF` - Git reference to build from: branch, tag, or commit SHA (default: `master`)
- `USER_UID` - User ID for the cubyz user (default: `1000`)
- `USER_GID` - Group ID for the cubyz group (default: `1000`)

Example with custom build args:

```bash
docker build \
  --build-arg GIT_REPO=https://github.com/your-fork/Cubyz.git \
  --build-arg GIT_REF=v0.1.0 \
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
        - GIT_REF=v0.1.0
        - USER_UID=1001
        - USER_GID=1001
```

### Volumes

- `/cubyz/saves` - Persistent world data

### Ports

- `47649/udp` - Game server port

## Troubleshooting

- **Container exited with code 137**  
    This may indicate insufficient memory. Monitor memory usage and consider allocating more resources.

- **Failed to create world: FileNotFound**  
    Ensure the volume for saves is correctly mounted, existing world is present at `saves/world` and has appropriate permissions.

- **Unknown connection from address: 192.168.x.x:30287**
    Use host networking mode `--network host` in Docker to avoid NAT issues

- **GLFW Error(65544): X11: Failed to load Xlib**  
    For < 0.1.0 versions headless server is not supported. Use `dev` tag instead. 
