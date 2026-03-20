#!/usr/bin/env bash
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(dirname "$SCRIPT_DIR")"
TEST_FILE="$ROOT_DIR/molecule/default/tests/test_lock_the_door.py"

# -- Colors ----------------------------------------------------------------
GREEN='\033[32m'
RED='\033[31m'
CYAN='\033[36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

echo ""
echo -e "  ${CYAN}${BOLD}=============================================="
echo -e "  ARIA — Automated Review & Intelligence Analyst"
echo -e "  Mission 1.2: Lock the Door"
echo -e "  ==============================================${RESET}"

cd "$ROOT_DIR"

# Activate project venv if it exists
if [ -f "$ROOT_DIR/venv/bin/activate" ]; then
    source "$ROOT_DIR/venv/bin/activate"
fi

# Run tests.
# conftest.py writes our pretty output to stderr.
# Redirect: stderr→terminal, stdout (pytest default noise)→/dev/null.
python3 -m pytest "$TEST_FILE" --tb=no --no-header -q 2>&1 1>/dev/null
EXIT_CODE=$?

echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}=============================================="
    echo -e "  ARIA: All objectives verified."
    echo -e "  Mission 1.2 status: COMPLETE"
    echo -e ""
    echo -e "  Cadet, the SSH Root Fairy has been defeated."
    echo -e "  Fleet SSH access is now hardened."
    echo -e "  The Starfall Defence Corps salutes your work."
    echo -e "  ==============================================${RESET}"
else
    echo -e "  ${RED}${BOLD}=============================================="
    echo -e "  ARIA: Deficiencies detected."
    echo -e "  Review the findings above and correct."
    echo -e "  Run 'make test' again when ready."
    echo -e "  ==============================================${RESET}"
fi

echo ""
exit $EXIT_CODE
