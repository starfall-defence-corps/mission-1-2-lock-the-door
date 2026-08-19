#!/usr/bin/env bash
# ARIA preflight diagnostics — verifies your machine is mission-ready
# before you burn time on a lab that cannot boot.
set -u

MISSION="Mission 1.2: Lock the Door"

GREEN='\033[32m'
RED='\033[31m'
YELLOW='\033[33m'
CYAN='\033[36m'
BOLD='\033[1m'
DIM='\033[2m'
RESET='\033[0m'

FAILURES=0

pass() { echo -e "    ${GREEN}✓${RESET} $1"; }
warn() { echo -e "    ${YELLOW}○${RESET} $1"; [ $# -gt 1 ] && echo -e "      ${DIM}↳ $2${RESET}"; }
fail() { echo -e "    ${RED}✗${RESET} $1"; echo -e "      ${DIM}↳ $2${RESET}"; FAILURES=$((FAILURES+1)); }

echo ""
echo -e "  ${CYAN}${BOLD}=============================================="
echo -e "  ARIA — Preflight Diagnostics"
echo -e "  ${MISSION}"
echo -e "  ==============================================${RESET}"
echo ""

# -- Docker ------------------------------------------------------------------
if ! command -v docker > /dev/null 2>&1; then
    fail "Docker CLI installed" "Install Docker Desktop: https://docs.docker.com/get-docker/"
elif ! docker info > /dev/null 2>&1; then
    fail "Docker daemon running" "Start Docker Desktop (or 'sudo systemctl start docker' on Linux) and re-run 'make doctor'"
else
    pass "Docker daemon running"
    if docker compose version > /dev/null 2>&1; then
        pass "Docker Compose v2 available"
    else
        fail "Docker Compose v2 available" "Update Docker Desktop — this lab needs the 'docker compose' plugin"
    fi
fi

# -- Core tools --------------------------------------------------------------
command -v git > /dev/null 2>&1 \
    && pass "Git installed" \
    || fail "Git installed" "Install git: https://git-scm.com/downloads"

if command -v python3 > /dev/null 2>&1; then
    if python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)' 2>/dev/null; then
        pass "Python $(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:2])))') (need 3.10+)"
        python3 -m venv -h > /dev/null 2>&1 \
            && pass "python3-venv available" \
            || fail "python3-venv available" "On Debian/Ubuntu: sudo apt install python3-venv"
    else
        fail "Python 3.10+ installed" "Found $(python3 --version 2>&1) — upgrade to 3.10 or newer"
    fi
else
    fail "Python 3.10+ installed" "Install Python 3: https://www.python.org/downloads/"
fi

# -- Lab environment ---------------------------------------------------------
SDC_RUNNING=$(docker ps --format '{{.Names}}' 2>/dev/null | grep -c '^sdc-' || true)
if [ "${SDC_RUNNING:-0}" -gt 0 ]; then
    THIS_LAB=$(docker ps --format '{{.Names}}' 2>/dev/null | grep '^sdc-' | tr '\n' ' ')
    warn "SDC lab containers already running: ${THIS_LAB}" "If these belong to another mission, run 'make destroy' there first — all labs share ports 2221-2223"
else
    PORTS_BUSY=""
    for port in 2221 2222 2223; do
        if (exec 3<>"/dev/tcp/127.0.0.1/$port") 2>/dev/null; then
            exec 3>&- 3<&- 2>/dev/null
            PORTS_BUSY="$PORTS_BUSY $port"
        fi
    done
    if [ -n "$PORTS_BUSY" ]; then
        fail "Ports 2221-2223 free" "Port(s)${PORTS_BUSY} in use — another mission lab or service is listening. Run 'make destroy' in the other mission, or free the port"
    else
        pass "Ports 2221-2223 free"
    fi
fi

# -- Disk space --------------------------------------------------------------
AVAIL_GB=$(df -k . 2>/dev/null | awk 'NR==2 {printf "%d", $4/1024/1024}')
if [ -n "${AVAIL_GB:-}" ]; then
    if [ "$AVAIL_GB" -ge 5 ]; then
        pass "Disk space: ${AVAIL_GB} GB free (need ~5 GB)"
    else
        warn "Disk space: only ${AVAIL_GB} GB free" "Lab images need a few GB — free up space if 'make setup' fails"
    fi
fi

# -- Verdict -----------------------------------------------------------------
echo ""
if [ "$FAILURES" -eq 0 ]; then
    echo -e "  ${GREEN}${BOLD}ARIA: All systems nominal. You are cleared for 'make setup'.${RESET}"
    echo ""
    exit 0
else
    echo -e "  ${RED}${BOLD}ARIA: ${FAILURES} deficiency(ies) detected. Fix the items above,"
    echo -e "  then run 'make doctor' again.${RESET}"
    echo ""
    exit 1
fi
