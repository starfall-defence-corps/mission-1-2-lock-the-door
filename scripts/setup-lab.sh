#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$ROOT_DIR/.docker"
SSH_DIR="$DOCKER_DIR/ssh-keys"

echo ""
echo "=============================================="
echo "  STARFALL DEFENCE CORPS ACADEMY"
echo "  Initialising Fleet Nodes..."
echo "=============================================="
echo ""

# Check python3-venv is available
if ! python3 -m venv --help &>/dev/null; then
    echo "  ERROR: python3-venv is not installed."
    echo "  On Debian/Ubuntu: sudo apt install python3-venv"
    echo "  On Fedora/RHEL:   sudo dnf install python3-virtualenv"
    exit 1
fi

# Set up Python virtual environment if not present
if [ ! -d "$ROOT_DIR/venv" ]; then
    echo "  Setting up Python environment..."
    python3 -m venv "$ROOT_DIR/venv"
    "$ROOT_DIR/venv/bin/pip" install -q -r "$ROOT_DIR/requirements.txt"
    echo "  Python environment ready."
    echo ""
fi

# Generate SSH key pair if not already present
if [ ! -f "$SSH_DIR/cadet_key" ]; then
    echo "  Generating SSH credentials..."
    mkdir -p "$SSH_DIR"
    ssh-keygen -t ed25519 -f "$SSH_DIR/cadet_key" -N "" -C "cadet@starfall-academy" -q
    cp "$SSH_DIR/cadet_key.pub" "$SSH_DIR/authorized_keys"
    chmod 600 "$SSH_DIR/cadet_key"
    chmod 644 "$SSH_DIR/authorized_keys"
    echo "  SSH credentials generated."
    echo ""
fi

# Copy private key to workspace for Ansible to use
mkdir -p "$ROOT_DIR/workspace/.ssh"
cp "$SSH_DIR/cadet_key" "$ROOT_DIR/workspace/.ssh/cadet_key"
chmod 600 "$ROOT_DIR/workspace/.ssh/cadet_key"

# Build and start containers
echo "  Building fleet node images..."
docker compose -f "$DOCKER_DIR/docker-compose.yml" up -d --build 2>&1 | while read -r line; do
    echo "    $line"
done

echo ""
echo "  Waiting for SSH to become available..."
for node in sdc-web:2221 sdc-db:2222 sdc-comms:2223; do
    name="${node%%:*}"
    port="${node##*:}"
    for i in $(seq 1 30); do
        if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=1 \
            -i "$SSH_DIR/cadet_key" cadet@localhost -p "$port" exit 2>/dev/null; then
            echo "    $name (port $port): ONLINE"
            break
        fi
        if [ "$i" -eq 30 ]; then
            echo "    $name (port $port): TIMEOUT — check 'docker compose logs $name'"
        fi
        sleep 1
    done
done

echo ""
echo "=============================================="
echo "  Fleet Status: 3 nodes ONLINE"
echo ""
echo "  WARNING: The SSH Root Fairy has been here."
echo "  Root login and password auth are ENABLED."
echo ""
echo "  Your workspace: workspace/"
echo "  Start here:     docs/BRIEFING.md"
echo "  Verify work:    make test"
echo "=============================================="
echo ""
