#!/usr/bin/env bash
# =============================================================================
# drift-daemon.sh — HARD MODE live-drift process (issue #49)
#
# Every DRIFT_INTERVAL seconds it re-applies the SSH Root Fairy's
# misconfigurations to the whole fleet. Runs in the background; launched by
# `make hardmode`, stopped by `make standdown` / `make reset` / `make destroy`.
#
# The cadet will find that running their playbook once is not enough: minutes
# later, the door is open again. The lesson — drift is continuous, so
# remediation must be too (idempotent playbook + a scheduled re-assert).
#
# Not intended to be run directly; use `make hardmode`.
# =============================================================================
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
# shellcheck source=scripts/drift-lib.sh
source "$SCRIPT_DIR/drift-lib.sh"

DRIFT_INTERVAL="${DRIFT_INTERVAL:-120}"
DRIFT_LOG="${ARIA_DRIFT_LOG:-$ROOT_DIR/.aria_drift.log}"

# Give the cadet a grace period before the first strike so a fresh `make
# hardmode` does not clobber work already in flight.
sleep "$DRIFT_INTERVAL"

while :; do
    hit="$(drift_revert_all)"
    ts="$(date +%s)"
    if [ -n "${hit// }" ]; then
        printf '%s reverted %s\n' "$ts" "$hit" >> "$DRIFT_LOG"
    else
        # Fleet is down (reset/destroy in progress) — nothing to drift.
        printf '%s idle (no nodes)\n' "$ts" >> "$DRIFT_LOG"
    fi
    sleep "$DRIFT_INTERVAL"
done
