#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$ROOT_DIR/.docker"

echo ""
echo "=============================================="
echo "  STARFALL DEFENCE CORPS ACADEMY"
echo "  Destroying Fleet..."
echo "=============================================="
echo ""

echo "  Stopping containers..."
docker compose -f "$DOCKER_DIR/docker-compose.yml" down -v 2>&1 | while read -r line; do
    echo "    $line"
done

echo "  Removing SSH keys..."
rm -rf "$DOCKER_DIR/ssh-keys"
rm -rf "$ROOT_DIR/workspace/.ssh"

echo "  Removing Python environment..."
rm -rf "$ROOT_DIR/venv"

echo ""
echo "  Fleet destroyed. Run 'make setup' to rebuild."
echo ""
