#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
DOCKER_DIR="$ROOT_DIR/.docker"

echo ""
echo "=============================================="
echo "  STARFALL DEFENCE CORPS ACADEMY"
echo "  Resetting Fleet Nodes..."
echo "=============================================="
echo ""

echo "  Destroying existing fleet..."
docker compose -f "$DOCKER_DIR/docker-compose.yml" down -v 2>&1 | while read -r line; do
    echo "    $line"
done

echo ""
echo "  Rebuilding fleet..."
# Reuse setup script for the rebuild
bash "$SCRIPT_DIR/setup-lab.sh"
