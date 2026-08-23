#!/usr/bin/env bash
# =============================================================================
# hardmode.sh — engage HARD MODE (issue #49)
#
# Opt-in. Launches the live-drift daemon in the background. Normal `make setup`
# is untouched; hard mode is entered only by an explicit `make hardmode`.
# =============================================================================
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/drift-lib.sh"

PID_FILE="$ROOT_DIR/.aria_drift.pid"
LOG_FILE="$ROOT_DIR/.aria_drift.log"
DRIFT_INTERVAL="${DRIFT_INTERVAL:-90}"

RED='\033[31m'; YELLOW='\033[33m'; CYAN='\033[36m'; BOLD='\033[1m'; RESET='\033[0m'

# The fleet must be up first.
up=0
for node in "${DRIFT_NODES[@]}"; do drift_node_up "$node" && up=$((up+1)); done
if [ "$up" -eq 0 ]; then
    echo -e "  ${RED}Fleet is offline.${RESET} Run 'make setup' before engaging hard mode."
    exit 1
fi

# Stop any prior daemon, then start fresh.
if [ -f "$PID_FILE" ]; then
    kill "$(cat "$PID_FILE")" 2>/dev/null || true
    rm -f "$PID_FILE"
fi
: > "$LOG_FILE"

DRIFT_INTERVAL="$DRIFT_INTERVAL" ARIA_DRIFT_LOG="$LOG_FILE" \
    nohup bash "$SCRIPT_DIR/drift-daemon.sh" >/dev/null 2>&1 &
echo "$!" > "$PID_FILE"

echo ""
echo -e "  ${RED}${BOLD}=============================================="
echo -e "  HARD MODE ENGAGED — LIVE DRIFT"
echo -e "  ==============================================${RESET}"
echo ""
echo -e "  ${YELLOW}A Voidborn persistence implant is now active on the fleet.${RESET}"
echo -e "  Every ${BOLD}${DRIFT_INTERVAL}s${RESET} it re-opens the door: root login back on,"
echo -e "  password auth back on, login grace reset — and a rogue root"
echo -e "  key re-planted on every node."
echo ""
echo -e "  Running your playbook once will ${BOLD}not${RESET} hold. Make your"
echo -e "  hardening ${BOLD}re-assert on a schedule${RESET} so the fleet self-heals."
echo ""
echo -e "  ${CYAN}make defend${RESET}     ARIA sabotages a node and grades whether"
echo -e "                  your defences self-heal."
echo -e "  ${CYAN}make standdown${RESET}  Recall the implant (leaves the fleet up)."
echo ""
echo -e "  First strike in ${DRIFT_INTERVAL}s. See docs/BRIEFING.md → HARD MODE."
echo ""
