---
CLASSIFICATION: CADET EYES ONLY
MISSION: 1.2 — LOCK THE DOOR
DOCUMENT: EXERCISES — Phase-by-Phase Operational Instructions
---

# EXERCISES — MISSION 1.2: LOCK THE DOOR

Complete each phase in sequence. Run `make test` after each phase. Do not advance until ARIA confirms compliance.

**Two directories, two purposes:**

- **Ansible commands** (`ansible`, `ansible-playbook`): Run from `workspace/` where `ansible.cfg` lives.
- **Make commands** (`make test`, `make reset`): Run from the **project root** (where the `Makefile` lives).

When a phase says "Run ARIA's Verification", return to the project root first:

```bash
cd ..        # from workspace/ back to project root
make test
cd workspace # return to workspace for the next phase
```

---

## PHASE 0: Launch the Fleet

> Before any mission can begin, your fleet must be online. Launch the fleet nodes and confirm they are operational.

### Step 0.1 — Start the Fleet

From the **project root directory** (not `workspace/`), run:

```bash
make setup
```

This builds the Docker containers, generates SSH credentials, and starts all three fleet nodes. Wait for the output to confirm:

```
  Fleet Status: 3 nodes ONLINE
```

### Step 0.2 — Activate the Python Environment

`make setup` creates a Python virtual environment with Ansible and testing tools. **Activate it** before running any Ansible commands:

```bash
source venv/bin/activate
```

Your terminal prompt will show `(venv)` when active. You need to do this once per terminal session. If you open a new terminal, activate again.

### Step 0.3 — If Things Go Wrong

If containers are in a bad state or you need a clean start at any point during the mission:

```bash
make reset
```

This destroys all containers and rebuilds them from scratch. Your work in `workspace/` (playbook, inventory) is preserved — only the containers are reset.

---

## PHASE 1: Understand the Mission

> The SSH Root Fairy has visited again — root login enabled on every node. Before writing a single line of code, understand the damage. Inspect the current state. Study the weapon you will use to fix it.

### What You Are Doing

You will inspect the current SSH configuration on all fleet nodes using ad-hoc commands, examine the skeleton playbook you will complete, and learn about the `lineinfile` module — the tool that will modify SSH configuration files across the fleet.

All Ansible commands in this phase are run from `workspace/`.

### Step 1.1 — Change Into the Workspace Directory

```bash
cd workspace
```

You must be in `workspace/` for Ansible to find `ansible.cfg` and the inventory path it references.

### Step 1.2 — Verify Fleet Connectivity

Before investigating SSH settings, confirm all nodes are reachable:

```bash
ansible all -m ping
```

All three nodes should return `SUCCESS` with `"ping": "pong"`. If any node is unreachable, run `make reset` from the project root and try again.

### Step 1.3 — Inspect the SSH Root Fairy's Damage

Run ad-hoc commands to see the current SSH configuration on every node:

**Check root login status:**

```bash
ansible all -m shell -a "grep PermitRootLogin /etc/ssh/sshd_config"
```

You will see `PermitRootLogin yes` on every node. This is the SSH Root Fairy's handiwork — root login is wide open.

**Check password authentication:**

```bash
ansible all -m shell -a "grep PasswordAuthentication /etc/ssh/sshd_config"
```

You will see `PasswordAuthentication yes` — another open door. Attackers can attempt password brute-force attacks against every account.

**Check login grace time:**

```bash
ansible all -m shell -a "grep LoginGraceTime /etc/ssh/sshd_config"
```

This line may be commented out (prefixed with `#`) or missing entirely. The default is 120 seconds — far too generous. An attacker gets two full minutes per connection attempt.

### Step 1.4 — Examine the Skeleton Playbook

Open `workspace/playbook.yml` in your editor. Read the entire file. You will see:

- A play targeting `all` hosts with `become: true` (root privileges)
- Three task slots marked `TODO` — one for each SSH configuration change
- A handler slot marked `TODO` — for restarting the SSH service
- Comments explaining what each task should do

**Do not write any code yet.** Understand the structure first.

### Step 1.5 — Read the Module Documentation

The `lineinfile` module is your primary weapon. Read its documentation:

```bash
ansible-doc lineinfile
```

Pay attention to these parameters:

| Parameter | Purpose |
|-----------|---------|
| `path` | The file to modify |
| `regexp` | A regular expression matching the line to replace |
| `line` | The exact line to insert or replace with |
| `state` | `present` (ensure line exists) or `absent` (ensure line removed) |

The `regexp` parameter is critical — it finds existing lines that match the pattern. If a match is found, that line is replaced with the `line` value. If no match is found, the `line` is added to the file.

### Step 1.6 — Run ARIA's Verification

Return to the project root and run:

```bash
cd ..
make test
cd workspace
```

ARIA checks that the playbook file exists and is valid YAML. Phase 1 tests (OPORD Structure) verify the playbook skeleton is present. Do not worry about later phases yet.

---

## PHASE 2: Write Your OPORD

> The damage is documented. The weapon is understood. Now write the operations order. Three tasks, three configuration lines, one playbook. Replace the TODOs with working `lineinfile` tasks.

### What You Are Doing

You will complete the three tasks in `workspace/playbook.yml`. Each task uses the `lineinfile` module to ensure a specific SSH configuration line is present in `/etc/ssh/sshd_config`.

### Step 2.1 — Task 1: Disable Root Login

Open `workspace/playbook.yml` and find the first TODO block. Replace it with a task that:

1. Uses the `ansible.builtin.lineinfile` module
2. Targets `/etc/ssh/sshd_config`
3. Uses a `regexp` to match any existing `PermitRootLogin` line (including commented-out lines)
4. Sets the `line` to `PermitRootLogin no`
5. Sets `state: present`

**Walkthrough of how a `lineinfile` task is structured:**

```yaml
    - name: Set MaxAuthTries to 3
      ansible.builtin.lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^#?MaxAuthTries'
        line: 'MaxAuthTries 3'
        state: present
```

**Breaking this down:**

| Line | Explanation |
|------|-------------|
| `- name:` | Human-readable description of what the task does |
| `ansible.builtin.lineinfile:` | The module to use |
| `path:` | The file to modify |
| `regexp: '^#?MaxAuthTries'` | Match lines starting with `MaxAuthTries` or `#MaxAuthTries` (the `#?` makes the comment character optional) |
| `line:` | The replacement line — what the file SHOULD contain |
| `state: present` | Ensure this line exists in the file |

Now write your Task 1 following this same pattern, but for `PermitRootLogin` instead of `MaxAuthTries`.

**Important YAML note:** Tasks must be indented under `tasks:` at the correct level. Each task starts with `- name:` at the same indentation level.

### Step 2.2 — Task 2: Disable Password Authentication

Find the second TODO block. Write a task using the same pattern:

- Target: `/etc/ssh/sshd_config`
- Regexp: match any existing `PasswordAuthentication` line
- Line: `PasswordAuthentication no`
- State: `present`

You have the pattern from Task 1. Apply it.

### Step 2.3 — Task 3: Set LoginGraceTime

Find the third TODO block. Write a task:

- Target: `/etc/ssh/sshd_config`
- Regexp: match any existing `LoginGraceTime` line
- Line: `LoginGraceTime 30`
- State: `present`

### Step 2.4 — Verify YAML Syntax

Before running anything, check your playbook has valid YAML syntax:

```bash
ansible-playbook playbook.yml --syntax-check
```

If you see errors, the most common causes are:

- **Incorrect indentation** — YAML is whitespace-sensitive. Tasks should align with each other.
- **Tabs instead of spaces** — YAML requires spaces. Never use tabs.
- **Missing colons or quotes** — Each `key: value` pair needs the colon.

Fix any syntax errors before proceeding.

### Step 2.5 — Run ARIA's Verification

```bash
cd ..
make test
cd workspace
```

At this point, ARIA may report partial progress. The tasks are written but handlers are not yet in place. Proceed to Phase 3.

---

## PHASE 3: Add the Handler

> Your OPORD has the tasks, but no contingency for service restart. When SSH configuration changes, the SSH daemon must be restarted for changes to take effect. Handlers are Ansible's mechanism for conditional restarts — they only fire when something actually changes.

### What You Are Doing

You will write an SSH restart handler and connect it to your three tasks using the `notify` keyword. This ensures the SSH service only restarts when a configuration change is actually made.

### Step 3.1 — Understand Handlers

In Ansible, a **handler** is a special task that only runs when notified. Here is how it works:

1. A regular task makes a change (e.g., modifies a config file) — its status becomes `changed`
2. That task includes `notify: Handler Name`
3. At the end of the play, Ansible runs any handlers that were notified
4. If the task did NOT change anything (status: `ok`), the handler is NOT triggered

This is important for services like SSH. You do not want to restart SSH on every playbook run — only when the configuration actually changed.

**Example handler for a different service:**

```yaml
  handlers:
    - name: Restart Nginx
      ansible.builtin.service:
        name: nginx
        state: restarted
```

**Example task that notifies a handler:**

```yaml
    - name: Update nginx configuration
      ansible.builtin.template:
        src: nginx.conf.j2
        dest: /etc/nginx/nginx.conf
      notify: Restart Nginx
```

### Step 3.2 — Write the SSH Restart Handler

Find the handler TODO block in `workspace/playbook.yml`. Replace it with a handler that:

1. Has the name `Restart SSH`
2. Uses the `ansible.builtin.service` module
3. Sets `name: ssh` (the SSH service name on Ubuntu)
4. Sets `state: restarted`

**Important:** The handler `name` must match exactly what you use in the `notify` keyword. Case matters.

### Step 3.3 — Add `notify` to Each Task

Go back to your three tasks from Phase 2. Add the following line to each task:

```yaml
      notify: Restart SSH
```

This line goes at the same indentation level as the module parameters (e.g., `path`, `regexp`, `line`). It tells Ansible: "If this task makes a change, trigger the Restart SSH handler."

### Step 3.4 — Verify YAML Syntax Again

```bash
ansible-playbook playbook.yml --syntax-check
```

Common mistakes at this stage:
- Handler section uses `handlers:` (not `handler:`)
- The `notify` value does not match the handler `name` exactly
- Indentation of handlers is wrong — handlers are at the same level as tasks (under the play, not nested inside tasks)

### Step 3.5 — Run ARIA's Verification

```bash
cd ..
make test
cd workspace
```

ARIA should now confirm your playbook has valid structure with tasks and handlers. Proceed to Phase 4.

---

## PHASE 4: Verify & Harden

> The OPORD is written. Before committing to live execution, perform a dry run. Then execute. Then verify the operation is clean — a second run should change nothing. This is the discipline of idempotency.

### What You Are Doing

You will execute your playbook in three stages: dry run (preview changes), live execution (apply changes), and idempotency verification (confirm second run is clean).

All commands are run from `workspace/`.

### Step 4.1 — Dry Run with --check --diff

```bash
ansible-playbook playbook.yml --check --diff
```

**What this does:**

| Flag | Meaning |
|------|---------|
| `--check` | Run in "check mode" — predict what would change, but do not actually change anything |
| `--diff` | Show the before/after difference for any file modifications |

You should see output indicating that three lines in `sshd_config` **would be** changed on each host. The diff output shows what the file looks like now versus what it would look like after the playbook runs.

**Why dry runs matter:** In production, you always preview changes before applying them. A playbook that modifies the wrong file or sets the wrong value can lock you out of every server in your fleet. `--check --diff` is your safety net.

If the dry run shows errors or unexpected changes, fix your playbook before proceeding.

### Step 4.2 — Execute for Real

```bash
ansible-playbook playbook.yml
```

Watch the output carefully. You should see:

- **Three `changed` tasks** per host (one for each `lineinfile` modification)
- **One handler execution** per host (`Restart SSH`)
- **A play recap** showing `changed=3` for each host

**Example output structure:**

```
PLAY [Lock the Door — SSH Hardening] ********

TASK [Gathering Facts] **********************
ok: [sdc-web]
ok: [sdc-db]
ok: [sdc-comms]

TASK [Disable root login] *******************
changed: [sdc-web]
changed: [sdc-db]
changed: [sdc-comms]

TASK [Disable password authentication] ******
changed: [sdc-web]
changed: [sdc-db]
changed: [sdc-comms]

TASK [Set LoginGraceTime to 30 seconds] *****
changed: [sdc-web]
changed: [sdc-db]
changed: [sdc-comms]

RUNNING HANDLER [Restart SSH] ***************
changed: [sdc-web]
changed: [sdc-db]
changed: [sdc-comms]

PLAY RECAP **********************************
sdc-comms  : ok=5    changed=4    ...
sdc-db     : ok=5    changed=4    ...
sdc-web    : ok=5    changed=4    ...
```

### Step 4.3 — Verify the Changes Took Effect

Use the same ad-hoc commands from Phase 1 to confirm the SSH Root Fairy's damage is repaired:

```bash
ansible all -m shell -a "grep PermitRootLogin /etc/ssh/sshd_config"
```

You should now see `PermitRootLogin no` on every node.

```bash
ansible all -m shell -a "grep PasswordAuthentication /etc/ssh/sshd_config"
```

You should see `PasswordAuthentication no`.

```bash
ansible all -m shell -a "grep LoginGraceTime /etc/ssh/sshd_config"
```

You should see `LoginGraceTime 30`.

### Step 4.4 — Idempotency Check

Run the playbook a second time:

```bash
ansible-playbook playbook.yml
```

This time, the output should show:

- **Zero `changed` tasks** — every task reports `ok` instead of `changed`
- **No handler execution** — the handler is not triggered because nothing changed
- **Play recap** showing `changed=0` for every host

**Why this matters:** Idempotency means "running the same operation twice produces the same result." A well-written playbook can be run a hundred times and only make changes when the actual system state differs from the desired state. This is the foundation of reliable automation.

If you see `changed` on the second run, something in your playbook is not idempotent. Check your `regexp` patterns — they may not be matching the lines your playbook just wrote.

### Step 4.5 — Final ARIA Verification

Return to the project root and run the full test suite:

```bash
cd ..
make test
```

ARIA will execute all phase checks:

1. **OPORD Structure** — Playbook exists, valid YAML, has tasks, has handler
2. **Dry Run** — `--check` succeeds without errors
3. **SSH Lockdown** — `PermitRootLogin no`, `PasswordAuthentication no`, `LoginGraceTime 30` present on all nodes
4. **Idempotency** — Second run produces `changed=0`

All phases must pass for the mission to be considered complete.

---

## MISSION COMPLETE — DEBRIEF CHECKLIST

Before closing this mission, confirm the following:

- [ ] Inspected current SSH state and identified the SSH Root Fairy's misconfigurations
- [ ] Understand what the `lineinfile` module does and how `regexp` works
- [ ] Completed all three tasks in `workspace/playbook.yml`
- [ ] Wrote the `Restart SSH` handler
- [ ] Added `notify: Restart SSH` to all three tasks
- [ ] Dry run (`--check --diff`) showed expected changes
- [ ] Playbook executed successfully — three configuration changes per host
- [ ] SSH service restarted via handler on all nodes
- [ ] Verified changes with ad-hoc commands
- [ ] Second playbook run produced `changed=0` (idempotent)
- [ ] `make test` — all ARIA checks pass

**What you learned in this mission:**

- [ ] Playbook structure (plays, tasks, handlers)
- [ ] The `lineinfile` module for managing configuration files
- [ ] The `regexp` parameter for matching existing lines
- [ ] Handlers and the `notify` keyword for conditional service restarts
- [ ] `--check` and `--diff` for safe dry runs
- [ ] Idempotency — the core principle of configuration management
- [ ] The `become: true` directive for privilege escalation

---

*SDC Cyber Command — 2187 — CADET EYES ONLY*
