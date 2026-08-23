#!/usr/bin/env bash
# =============================================================================
# defend-check.sh — HARD MODE graded challenge (issue #49)
#
# ARIA sabotages every node (re-opens SSH, plants the implant) and then watches
# whether the fleet *self-heals*. A one-shot playbook run leaves the fleet open
# forever → FAIL. A scheduled re-assert (cron / ansible-pull) re-closes the
# door within a minute → PASS. This is the drift-remediation lesson, graded.
# =============================================================================
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
source "$SCRIPT_DIR/drift-lib.sh"

PID_FILE="$ROOT_DIR/.aria_drift.pid"
DEFEND_TIMEOUT="${DEFEND_TIMEOUT:-80}"   # seconds; must exceed a 1-minute cron
POLL="${DEFEND_POLL:-5}"

GREEN='\033[32m'; RED='\033[31m'; CYAN='\033[36m'; YELLOW='\033[33m'
BOLD='\033[1m'; DIM='\033[2m'; RESET='\033[0m'

echo ""
echo -e "  ${CYAN}${BOLD}=============================================="
echo -e "  ARIA — HARD MODE: DRIFT RESILIENCE TEST"
echo -e "  ==============================================${RESET}"
echo ""

# Fleet must be up.
up=0
for node in "${DRIFT_NODES[@]}"; do drift_node_up "$node" && up=$((up+1)); done
if [ "$up" -eq 0 ]; then
    echo -e "  ${RED}Fleet is offline.${RESET} Run 'make setup' first."
    exit 1
fi

# Pause the live-drift daemon so only the cadet's defences are under test.
if [ -f "$PID_FILE" ]; then
    kill "$(cat "$PID_FILE")" 2>/dev/null || true
    rm -f "$PID_FILE"
    echo -e "  ${DIM}Live-drift daemon paused for grading. Re-engage with 'make hardmode'.${RESET}"
fi

# Advisory: is any scheduled re-assert deployed?
reassert=0
for node in "${DRIFT_NODES[@]}"; do
    if docker exec "$node" bash -c '
        { crontab -l 2>/dev/null; crontab -l -u root 2>/dev/null;
          cat /etc/cron.d/* 2>/dev/null; cat /etc/crontab 2>/dev/null; } \
        | grep -qiE "ssh|hardening|ansible|permitroot|reassert|re-assert"
    ' >/dev/null 2>&1; then
        reassert=$((reassert+1))
    fi
done
if [ "$reassert" -gt 0 ]; then
    echo -e "  Scheduled re-assert detected on ${reassert}/${#DRIFT_NODES[@]} node(s)."
else
    echo -e "  ${YELLOW}No scheduled re-assert detected.${RESET} A one-time fix will not survive."
fi
echo ""

# --- Sabotage -------------------------------------------------------------
echo -e "  ${RED}Sabotaging the fleet…${RESET} re-opening SSH and planting the implant."
hit="$(drift_revert_all)"
echo -e "  ${DIM}Hit: ${hit:-none}${RESET}"
echo ""
echo -e "  Observing self-heal for up to ${BOLD}${DEFEND_TIMEOUT}s${RESET} ${DIM}(polling every ${POLL}s)${RESET}…"

# --- Observe self-heal ----------------------------------------------------
# `recovered` is a space-padded set of node names (portable to bash 3.2).
recovered=" "
elapsed=0
while [ "$elapsed" -lt "$DEFEND_TIMEOUT" ]; do
    all_ok=1
    line="  ${DIM}[t+${elapsed}s]${RESET} "
    for node in "${DRIFT_NODES[@]}"; do
        if [ "${recovered#* $node }" != "$recovered" ]; then
            line+="${GREEN}${node}✔${RESET} "
            continue
        fi
        if drift_node_hardened "$node" && ! drift_node_has_implant "$node"; then
            recovered="${recovered}${node} "
            line+="${GREEN}${node}✔${RESET} "
        else
            all_ok=0
            line+="${RED}${node}✗${RESET} "
        fi
    done
    echo -e "$line"
    [ "$all_ok" -eq 1 ] && break
    sleep "$POLL"
    elapsed=$((elapsed+POLL))
done

# --- Verdict --------------------------------------------------------------
echo ""
open_nodes=()
for node in "${DRIFT_NODES[@]}"; do
    if [ "${recovered#* $node }" = "$recovered" ]; then open_nodes+=("$node"); fi
done

if [ "${#open_nodes[@]}" -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}=============================================="
    echo -e "  ARIA: DRIFT REPELLED — the fleet self-healed."
    echo -e "  ==============================================${RESET}"
    echo ""
    echo -e "  Every node re-closed the door on its own. Your hardening"
    echo -e "  re-asserts on a schedule — exactly how you survive an"
    echo -e "  adversary who never stops. That is drift remediation."
    echo ""
    echo -e "  ${CYAN}Voidborn implant: contained.${RESET}"
    echo ""
    exit 0
else
    echo -e "  ${RED}${BOLD}=============================================="
    echo -e "  ARIA: FLEET STILL COMPROMISED after ${DEFEND_TIMEOUT}s."
    echo -e "  ==============================================${RESET}"
    echo ""
    echo -e "  Doors still open on: ${BOLD}${open_nodes[*]}${RESET}"
    echo ""
    echo -e "  A one-shot fix cannot hold against continuous drift. Your"
    echo -e "  playbook must ${BOLD}re-assert on a schedule${RESET} so the fleet"
    echo -e "  re-hardens itself. Deploy a re-assert (ansible.builtin.cron"
    echo -e "  or ansible-pull) — see docs/HINTS.md → HARD MODE."
    echo ""
    echo -e "  ${DIM}The fleet is currently open. Run your playbook or 'make reset'.${RESET}"
    echo ""
    exit 1
fi
