# Mission 1.2: Lock the Door — Hints & Troubleshooting Guide

**Rank**: Cadet (Maximum Scaffolding)

This guide is your safety net. If something is not working, the answer is likely here. Read the relevant section carefully before asking for help.

---

## Phase 1 Hints: Understanding the Mission

**Reading ad-hoc command output:**

When you run `ansible all -m shell -a "grep PermitRootLogin /etc/ssh/sshd_config"`, the output shows each host followed by its result:

```
sdc-web | CHANGED | rc=0 >>
PermitRootLogin yes

sdc-db | CHANGED | rc=0 >>
PermitRootLogin yes

sdc-comms | CHANGED | rc=0 >>
PermitRootLogin yes
```

The `CHANGED` status is normal for shell commands — Ansible considers any shell execution a change. The actual line content follows the `>>` marker. Look at the value after each directive to understand the current state.

**If a grep returns nothing:** The line may be commented out (prefixed with `#`) or absent entirely. Try a broader search:

```bash
ansible all -m shell -a "grep -i logingraceTime /etc/ssh/sshd_config"
```

The `-i` flag makes the search case-insensitive.

**Understanding `ansible-doc` output:**

The `ansible-doc lineinfile` command shows extensive documentation. Focus on the EXAMPLES section near the bottom — it contains working task snippets you can adapt.

---

## Phase 2 Hints: Writing lineinfile Tasks

**The `lineinfile` module — complete example:**

This example sets `MaxAuthTries 3` in the SSH config. It is NOT one of your mission tasks — it is a demonstration of the pattern:

```yaml
    - name: Set MaxAuthTries to 3
      ansible.builtin.lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^#?MaxAuthTries'
        line: 'MaxAuthTries 3'
        state: present
      notify: Restart SSH
```

**Understanding `regexp: '^#?MaxAuthTries'`:**

| Part | Meaning |
|------|---------|
| `^` | Start of line |
| `#?` | An optional `#` character (matches commented and uncommented lines) |
| `MaxAuthTries` | The literal directive name |

This pattern matches both `MaxAuthTries 6` and `#MaxAuthTries 6`, ensuring the module replaces the line whether it is active or commented out.

**Apply this same pattern** to `PermitRootLogin`, `PasswordAuthentication`, and `LoginGraceTime`. The only things that change between tasks are the directive name and value.

**YAML indentation for tasks:**

Tasks live under the `tasks:` key. Each task starts with `- name:` at the same indentation level. Module parameters are indented under the module name:

```yaml
  tasks:
    - name: First task
      ansible.builtin.lineinfile:
        path: /some/file
        regexp: '^pattern'
        line: 'replacement'
        state: present
      notify: Restart SSH

    - name: Second task
      ansible.builtin.lineinfile:
        path: /some/file
        regexp: '^other_pattern'
        line: 'other replacement'
        state: present
      notify: Restart SSH
```

**"The offending line appears to be..." YAML error:**

This means your indentation is wrong. Count your spaces carefully. Use 2 spaces per indentation level. Never mix tabs and spaces.

**"tasks: []" must be replaced:**

The skeleton playbook has `tasks: []` — an empty list. When you add real tasks, remove the `[]` and add tasks on the following lines with proper indentation. The same applies to `handlers: []`.

---

## Phase 3 Hints: Handlers

**Handler syntax — example for a DIFFERENT service (not SSH):**

```yaml
  handlers:
    - name: Restart Nginx
      ansible.builtin.service:
        name: nginx
        state: restarted
```

The handler for SSH follows the same pattern. The service name on Ubuntu is `ssh` (not `sshd` — that is the Red Hat/CentOS convention).

**The `notify` keyword:**

Add `notify` at the module level (same indentation as `path`, `regexp`, etc.):

```yaml
    - name: Some task
      ansible.builtin.lineinfile:
        path: /etc/some/config
        regexp: '^Setting'
        line: 'Setting value'
        state: present
      notify: Restart SSH
```

**Common mistake — `notify` must match the handler `name` exactly:**

- Handler: `- name: Restart SSH` (capital R, capital S)
- Notify: `notify: Restart SSH` (must be identical)

If the names do not match, Ansible will silently skip the handler. No error is shown — the handler just never fires.

**"handlers" indentation:**

Handlers are at the same level as `tasks` — both are children of the play. Do not nest handlers inside tasks:

```yaml
- name: My Play
  hosts: all
  become: true

  tasks:
    - name: A task
      ...

  handlers:
    - name: A handler
      ...
```

---

## Phase 4 Hints: Verification & Idempotency

**What `--check` does:**

Check mode simulates the playbook without making changes. Ansible predicts what WOULD change and reports it. If check mode fails with an error, your playbook has a structural problem.

**What `--diff` shows:**

Diff mode displays the before/after content of modified files. Combined with `--check`, it previews changes without applying them:

```
--- before: /etc/ssh/sshd_config
+++ after: /etc/ssh/sshd_config
@@ -1,3 +1,3 @@
-PermitRootLogin yes
+PermitRootLogin no
```

Lines starting with `-` are removed. Lines starting with `+` are added.

**What idempotency means:**

An idempotent operation produces the same result whether it runs once or a hundred times. For your playbook:

- **First run**: `changed=3` (three config lines modified) + handler fires
- **Second run**: `changed=0` (config already correct) + handler does NOT fire

If your second run still shows `changed`, your `regexp` pattern may not be matching the line your playbook just wrote. For example, if your regexp is `'^PermitRootLogin yes'` it will not match `PermitRootLogin no` on the second run, so `lineinfile` adds a duplicate line instead of recognising it is already correct.

**Fix:** Use a regexp that matches the directive name, not the full line: `'^#?PermitRootLogin'`

---

## Connection Hints

**"Connection refused"**
The containers are not running. Start them with:
```
make setup
```

Then verify they are up:
```
docker ps
```
You should see `sdc-web`, `sdc-db`, and `sdc-comms` in the list.

**"Permission denied (publickey)"**
Ansible cannot find or use your SSH key. Check that the key file exists at `workspace/.ssh/cadet_key`. If the path in your inventory or `ansible.cfg` does not match the actual file location, correct it.

**"Host key verification failed"**
The `ansible.cfg` file in this mission already disables strict host key checking. If you are running Ansible manually outside of the project directory and hit this error, add:
```
-o StrictHostKeyChecking=no
```
as an SSH argument, or set `host_key_checking = False` in an `ansible.cfg`.

---

## WSL (Windows Subsystem for Linux) Hints

**"Ansible is ignoring my ansible.cfg"**
On WSL, Windows-mounted directories have `777` permissions by default. Ansible treats world-writable directories as untrusted and will silently ignore any `ansible.cfg` found in them.

**Quick fix — set the ANSIBLE_CONFIG environment variable:**
```
export ANSIBLE_CONFIG=$(pwd)/ansible.cfg
```
Run this from the `workspace/` directory before running Ansible commands. Add it to your `~/.bashrc` or `~/.zshrc` to make it persistent.

**Permanent fix — configure WSL mount options:**
Create or edit `/etc/wsl.conf`:
```ini
[automount]
options = "metadata,umask=22,fmask=11"
```
Then restart WSL (`wsl --shutdown` from PowerShell). This sets proper file permissions on Windows-mounted directories.

---

## General Troubleshooting

**If everything is broken and you are not sure where to start:**
```
make reset
```
This rebuilds the entire fleet from scratch. You will not lose your playbook — only the containers are reset. Note: resetting also restores the SSH Root Fairy's misconfigurations, so you will need to run your playbook again.

**"make: *** No targets specified" or "make: *** No rule to make target"**
You are in the wrong directory. `make` commands must be run from the project root where the `Makefile` is located — not from `workspace/`. Run `cd ..` to go back to the project root.

**If `make test` fails:**
Read the ARIA error message carefully. ARIA tells you specifically what it expected versus what it found. Fix that one thing, then run `make test` again.

**Check container status at any time:**
```
docker ps
```
All three containers (`sdc-web`, `sdc-db`, `sdc-comms`) should appear with a status of `Up`.

**Quick diagnostic sequence when something is not working:**
1. `docker ps` — are containers running?
2. `ansible all -m ping` — can Ansible reach them?
3. `ansible-playbook playbook.yml --syntax-check` — is the playbook valid YAML?
4. Check indentation in `workspace/playbook.yml`
5. Check `ansible.cfg` is present and points to the correct inventory path

---

## Useful Commands Reference

| Command | Purpose |
|---------|---------|
| `ansible-doc lineinfile` | Full module documentation |
| `ansible-doc service` | Handler module documentation |
| `ansible-playbook playbook.yml --syntax-check` | Validate YAML without running |
| `ansible-playbook playbook.yml --check --diff` | Dry run with diff preview |
| `ansible-playbook playbook.yml` | Execute the playbook |
| `ansible-playbook playbook.yml -v` | Execute with verbose output |
| `ansible all -m ping` | Test connectivity to all nodes |
| `ansible all -m shell -a "command"` | Run ad-hoc shell command on all nodes |

---

## CRITICAL SPOILER — Full Playbook Solution

> **STOP.** Only read this section if you are truly stuck and have exhausted all other hints. Writing the playbook yourself is the entire point of this mission. If you copy this solution, you are only cheating yourself.

> **LAST WARNING.** Scroll down only if you have spent real effort and need to compare your work to a working example.

<br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br><br>

```yaml
---
- name: Lock the Door — SSH Hardening
  hosts: all
  become: true

  tasks:
    - name: Disable root login
      ansible.builtin.lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^#?PermitRootLogin'
        line: 'PermitRootLogin no'
        state: present
      notify: Restart SSH

    - name: Disable password authentication
      ansible.builtin.lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^#?PasswordAuthentication'
        line: 'PasswordAuthentication no'
        state: present
      notify: Restart SSH

    - name: Set LoginGraceTime to 30 seconds
      ansible.builtin.lineinfile:
        path: /etc/ssh/sshd_config
        regexp: '^#?LoginGraceTime'
        line: 'LoginGraceTime 30'
        state: present
      notify: Restart SSH

  handlers:
    - name: Restart SSH
      ansible.builtin.service:
        name: ssh
        state: restarted
```

This is the complete, working playbook. If your version differs, compare each task carefully — check the `regexp` patterns, the `notify` keywords, and the handler name.

---

*SDC Cyber Command — 2187 — CADET EYES ONLY*
