# Mission 1.2: Lock the Door — Progress Tracker

**Rank**: Cadet
**Mission Progress**: 2 of 5 toward Ensign

Check each item off as you complete it. If a phase is blocked, see `docs/HINTS.md`.

---

## Phase 1: Understand the Mission

- [ ] Fleet nodes are online (`make setup` succeeded)
- [ ] Verified connectivity with `ansible all -m ping`
- [ ] Inspected current SSH state — `PermitRootLogin yes` confirmed on all nodes
- [ ] Inspected current SSH state — `PasswordAuthentication yes` confirmed on all nodes
- [ ] Inspected current SSH state — `LoginGraceTime` missing or commented out on all nodes
- [ ] Reviewed skeleton playbook at `workspace/playbook.yml`
- [ ] Read `ansible-doc lineinfile` module documentation

---

## Phase 2: Write Your OPORD

- [ ] Completed Task 1: Disable root login (`PermitRootLogin no`)
- [ ] Completed Task 2: Disable password authentication (`PasswordAuthentication no`)
- [ ] Completed Task 3: Set login grace time (`LoginGraceTime 30`)
- [ ] Playbook passes syntax check (`ansible-playbook playbook.yml --syntax-check`)

---

## Phase 3: Add the Handler

- [ ] Wrote the `Restart SSH` handler using `ansible.builtin.service`
- [ ] Added `notify: Restart SSH` to Task 1
- [ ] Added `notify: Restart SSH` to Task 2
- [ ] Added `notify: Restart SSH` to Task 3
- [ ] Playbook still passes syntax check after handler changes

---

## Phase 4: Verify & Harden

- [ ] Dry run succeeded (`ansible-playbook playbook.yml --check --diff`)
- [ ] Playbook executed successfully — `changed=3` per host on first run
- [ ] Handler fired — SSH restarted on all nodes
- [ ] Verified changes with ad-hoc commands (all three directives correct)
- [ ] Second run is idempotent — `changed=0` on all hosts
- [ ] `make test` — all ARIA checks pass

---

## Verification

- [ ] `make test` — all ARIA checks pass
