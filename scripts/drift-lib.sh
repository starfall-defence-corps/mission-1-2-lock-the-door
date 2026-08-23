#!/usr/bin/env bash
# =============================================================================
# drift-lib.sh — shared helpers for HARD MODE (issue #49)
#
# HARD MODE simulates a Voidborn persistence implant: a range-side process that
# re-applies the SSH Root Fairy's misconfigurations on a timer. A one-shot fix
# will not hold — students must make their hardening *re-assert* on a schedule.
#
# These helpers act on the fleet via `docker exec` (not SSH) so the drift is
# independent of whatever state the cadet has left sshd in. Sourced by
# drift-daemon.sh and defend-check.sh.
# =============================================================================

# Fleet node container names (see .docker/docker-compose.yml).
DRIFT_NODES=(sdc-web sdc-db sdc-comms)

# A fake "Voidborn implant" root key. Deliberately non-functional (bogus base64)
# — its only purpose is to be a recognisable artefact the cadet must purge.
DRIFT_IMPLANT_TAG="voidborn-implant@root-fairy"
DRIFT_IMPLANT_KEY="ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIVOIDBORNimplant000000000000000000000000000000 ${DRIFT_IMPLANT_TAG}"

# True if the named container is running.
drift_node_up() {
    [ "$(docker inspect -f '{{.State.Running}}' "$1" 2>/dev/null)" = "true" ]
}

# Revert one node to the SSH Root Fairy's insecure baseline and plant the
# implant. Restarts sshd so the change is live.
drift_revert_node() {
    local node="$1"
    drift_node_up "$node" || return 1
    # Patterns match the directive at line-start (optionally a single leading
    # "#", no space) followed by whitespace — i.e. real config lines only, never
    # prose comments like "# PasswordAuthentication. Depending on your PAM…".
    docker exec "$node" bash -c '
        cfg=/etc/ssh/sshd_config
        sed -i -E "s/^#?PermitRootLogin[[:space:]].*/PermitRootLogin yes/" "$cfg"
        grep -qE "^PermitRootLogin[[:space:]]"       "$cfg" || echo "PermitRootLogin yes"        >> "$cfg"
        sed -i -E "s/^#?PasswordAuthentication[[:space:]].*/PasswordAuthentication yes/" "$cfg"
        grep -qE "^PasswordAuthentication[[:space:]]" "$cfg" || echo "PasswordAuthentication yes" >> "$cfg"
        sed -i -E "s/^#?LoginGraceTime[[:space:]].*/LoginGraceTime 120/" "$cfg"
        grep -qE "^LoginGraceTime[[:space:]]"         "$cfg" || echo "LoginGraceTime 120"         >> "$cfg"
        mkdir -p /root/.ssh && chmod 700 /root/.ssh
        grep -q "'"$DRIFT_IMPLANT_TAG"'" /root/.ssh/authorized_keys 2>/dev/null \
            || echo "'"$DRIFT_IMPLANT_KEY"'" >> /root/.ssh/authorized_keys
        systemctl restart ssh 2>/dev/null || service ssh restart 2>/dev/null || true
    ' >/dev/null 2>&1
}

# Return 0 if a node currently holds all three hardened directives.
# Mirrors ARIA's grading regexes in test_lock_the_door.py.
drift_node_hardened() {
    local node="$1"
    drift_node_up "$node" || return 2
    docker exec "$node" bash -c '
        grep -qE "^PermitRootLogin[[:space:]]+no"        /etc/ssh/sshd_config &&
        grep -qE "^PasswordAuthentication[[:space:]]+no" /etc/ssh/sshd_config &&
        grep -qE "^LoginGraceTime[[:space:]]+30"         /etc/ssh/sshd_config
    ' >/dev/null 2>&1
}

# Return 0 if the implant key is still present on a node.
drift_node_has_implant() {
    local node="$1"
    drift_node_up "$node" || return 2
    docker exec "$node" bash -c \
        'grep -q "'"$DRIFT_IMPLANT_TAG"'" /root/.ssh/authorized_keys 2>/dev/null' \
        >/dev/null 2>&1
}

# Revert every node. Echoes the names it hit.
drift_revert_all() {
    local hit=()
    for node in "${DRIFT_NODES[@]}"; do
        if drift_revert_node "$node"; then hit+=("$node"); fi
    done
    echo "${hit[*]}"
}
