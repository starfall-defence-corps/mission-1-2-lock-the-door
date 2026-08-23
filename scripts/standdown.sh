#!/usr/bin/env bash
# =============================================================================
# standdown.sh — disengage HARD MODE (issue #49)
#
# Stops the live-drift daemon and leaves the fleet running. Does not re-harden
# the nodes — run your playbook (or `make reset`) to restore a clean baseline.
# =============================================================================
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
PID_FILE="$ROOT_DIR/.aria_drift.pid"

GREEN='\033[32m'; DIM='\033[2m'; RESET='\033[0m'

if [ -f "$PID_FILE" ]; then
    kill "$(cat "$PID_FILE")" 2>/dev/null || true
    rm -f "$PID_FILE"
    rm -f "$ROOT_DIR/.aria_drift.log"
    echo -e "  ${GREEN}Hard mode disengaged.${RESET} The implant is dormant."
    echo -e "  ${DIM}Nodes are left as-is — run your playbook or 'make reset' to restore.${RESET}"
else
    echo "  Hard mode is not currently engaged."
fi
