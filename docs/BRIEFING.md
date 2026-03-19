---
CLASSIFICATION: CADET EYES ONLY
MISSION: 1.2 — LOCK THE DOOR
THEATRE: Starfall Defence Corps Academy
AUTHORITY: SDC Cyber Command, 2187
---

# OPERATION ORDER — MISSION 1.2: LOCK THE DOOR

---

## 1. SITUATION

### 1a. Enemy Forces

Voidborn operative **THE SSH ROOT FAIRY** has swept through the fleet. Modus operandi: SSH misconfiguration. Root login enabled on every node. Password authentication wide open. Login grace periods left at insecure defaults. The digital equivalent of leaving your front door open with a sign saying "COME IN."

### 1b. Friendly Forces

The **Starfall Defence Corps (SDC)** fleet has been inventoried (Mission 1.1), but remains dangerously exposed. SSH access controls are non-existent. Every node is one brute-force attempt away from full compromise. The fleet is catalogued but undefended.

### 1c. Attachments / Support

**ARIA** (Automated Review & Intelligence Analyst) is assigned to this mission. ARIA will verify your playbook structure, execution results, and idempotency compliance.

### 1d. Operational Tool

All operations will be conducted using **ANSIBLE** — *Automated Network for Secure Infrastructure, Baseline Lockdown & Enforcement*. This mission introduces **playbooks** — your first written OPORD (Operations Order) that ANSIBLE executes across the fleet.

---

## 2. MISSION

Write and execute an Ansible playbook to harden SSH configuration across all fleet nodes. Disable root login. Disable password authentication. Set a strict login grace period. Ensure the SSH service restarts when configuration changes are applied.

**End state**: Every node hardened against SSH-based attack vectors. Configuration changes verified as idempotent — running the playbook twice produces zero changes on the second run.

---

## 3. EXECUTION

### 3a. Commander's Intent

The fleet was catalogued in Mission 1.1. Now it must be defended. A verified inventory is useless if every node can be compromised through default SSH settings. This mission establishes the first line of defence: SSH hardening applied uniformly across every fleet node via automation. Manual configuration is not acceptable — the playbook must be the single source of truth.

### 3b. Concept of Operations

Four sequential phases. Complete each phase before advancing. Full procedural detail is in **EXERCISES.md**.

| Phase | Task | Objective |
|-------|------|-----------|
| 1 | Understand the Mission | Inspect current SSH state, review the skeleton playbook, learn `lineinfile` |
| 2 | Write Your OPORD | Complete the three `lineinfile` tasks in the playbook |
| 3 | Add the Handler | Write the SSH restart handler, add `notify` to each task |
| 4 | Verify & Harden | Dry run, execute, confirm idempotency, pass all ARIA checks |

### 3c. Fleet Assets

All nodes are accessible via SSH. Credentials are uniform across the fleet. Inventory is pre-configured from Mission 1.1.

| Designation | Role | IP Address | SSH Port |
|-------------|------|------------|----------|
| `sdc-web` | Fleet Web Server | localhost | 2221 |
| `sdc-db` | Fleet Database Server | localhost | 2222 |
| `sdc-comms` | Fleet Communications Relay | localhost | 2223 |

**SSH User**: `cadet`
**Authentication**: SSH key located at `workspace/.ssh/cadet_key`

### 3d. Rules of Engagement

- Cadets must write the playbook themselves. Copying solutions verbatim defeats the mission objective.
- The skeleton playbook at `workspace/playbook.yml` contains TODO markers. Replace them with working tasks.
- All changes must be applied via the playbook — do not manually edit `/etc/ssh/sshd_config` on the nodes.
- All findings are to be reproducible. If ARIA cannot verify your work, your work is not complete.

---

## 4. SUPPORT

| Resource | Function | Command |
|----------|----------|---------|
| **ARIA** | Verifies mission compliance; reports pass/fail per phase | `make test` |
| **HINTS.md** | Operational guidance if mission stalls | — |
| **Fleet Reset** | Rebuilds all fleet containers from scratch | `make reset` |
| **Module Docs** | Ansible module documentation | `ansible-doc lineinfile` |

Run `make test` after each phase. Do not advance until ARIA confirms the phase complete.

Consulting **HINTS.md** is authorised at Cadet rank. Using available intelligence is not weakness — it is doctrine.

---

## 5. COMMAND AND SIGNAL

**Reporting**: ARIA is your automated reporting chain. Her output is your after-action record.

**Commander's Final Order**: The SSH Root Fairy's damage will be remediated on every node. Root login disabled. Password authentication disabled. Login grace period enforced. The playbook is your weapon — write it, verify it, and execute it. No exceptions.

Proceed to **EXERCISES.md** for phase-by-phase operational instructions.

---

*SDC Cyber Command — 2187 — CADET EYES ONLY*
