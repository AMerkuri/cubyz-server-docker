# Cubyz Headless Server Dockerfile
# Multi-stage build for minimal final image

# Stage 1: Build stage
FROM alpine:3.20 AS builder

# Build arguments for repository configuration
ARG GIT_REPO=https://github.com/PixelGuys/Cubyz
ARG GIT_BRANCH=master

# Install build dependencies
RUN apk add --no-cache bash build-base linux-headers wget xz tar ca-certificates git curl \
    && update-ca-certificates

# Set working directory
WORKDIR /build

# Clone repository
RUN git clone --depth 1 --branch ${GIT_BRANCH} ${GIT_REPO} . && \
    ls -la

# Download and install Zig compiler
RUN ./scripts/install_compiler_linux.sh

# Build the server in release mode for Alpine (musl libc)
RUN ARCH=$(uname -m) && \
    echo "Building for native architecture: $ARCH with musl libc" && \
    # Retry the build up to 3 times if it fails due to network issues
    for i in 1 2 3; do \
    ./compiler/zig/zig build \
    -Dtarget=${ARCH}-linux-musl \
    -Doptimize=ReleaseFast \
    -Drelease=true \
    -Dcpu=baseline && break || \
    (echo "Build attempt $i failed, retrying..." && sleep 5); \
    done

# Stage 2: Runtime stage
FROM alpine:3.20

# Build arguments for user configuration
ARG USER_UID=1000
ARG USER_GID=1000

# Install netcat for healthcheck
RUN apk add --no-cache netcat-openbsd

# Create non-root user with specified UID/GID
RUN addgroup -g ${USER_GID} cubyz && \
    adduser -D -u ${USER_UID} -G cubyz cubyz

# Set working directory
WORKDIR /cubyz

# Copy the compiled binary from builder
COPY --from=builder /build/zig-out/bin/Cubyz /cubyz/Cubyz

# Copy assets
COPY --from=builder /build/assets/ /cubyz/assets/

# Copy mods
COPY --from=builder /build/mods/ /cubyz/mods/

# Copy entrypoint script from local context
COPY docker-entrypoint.sh /cubyz/docker-entrypoint.sh

# Create saves directory and make entrypoint executable
RUN mkdir -p /cubyz/saves && \
    chmod +x /cubyz/docker-entrypoint.sh

# Set ownership
RUN chown -R cubyz:cubyz /cubyz

# Switch to non-root user
USER cubyz

# Expose default server port
EXPOSE 47649/udp

# Volume for persistent world data
# VOLUME ["/cubyz/saves"]

# Set environment variable defaults
ENV CUBYZ_WORLD_NAME=world

# Use the entrypoint script
ENTRYPOINT ["/cubyz/docker-entrypoint.sh"]
