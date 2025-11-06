#!/bin/sh
set -eu

WORLD_NAME=${CUBYZ_WORLD_NAME:-world}

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
