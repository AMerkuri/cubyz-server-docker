#!/bin/sh
set -eu

WORLD_NAME=${CUBYZ_WORLD_NAME:-world}

# Fix permissions if running as root
if [ "$(id -u)" = "0" ]; then
    echo "Running as root, fixing permissions on /cubyz/saves..."
    chown -R cubyz:cubyz /cubyz/saves 2>/dev/null || true
    echo "Dropping privileges to cubyz user..."
    exec su-exec cubyz "$0" "$@"
fi

# echo "Using data directory: $DATA_DIR"
echo "Using world name: $WORLD_NAME"

cat > launchConfig.zon <<EOF
.{
	.cubyzDir = ".",
	.headlessServer = true,
	.autoEnterWorld = "$WORLD_NAME",
}
EOF

exec ./Cubyz "$@"
