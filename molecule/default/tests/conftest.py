"""
ARIA Custom Test Reporter
Provides color-coded, phase-grouped output for mission verification.

Writes all output to stderr so check-work.sh can discard pytest's
default stdout while preserving our formatted display.
"""
import os
import pytest
import sys

# -- Phase and test name mappings -------------------------------------------

PHASES = {
    "TestPlaybookStructure": ("1", "OPORD Structure"),
    "TestDryRun":            ("2", "Dry Run"),
    "TestSSHHardening":      ("3", "SSH Lockdown"),
    "TestIdempotency":       ("4", "Idempotency"),
}

FRIENDLY = {
    "test_playbook_exists":             "Playbook file exists",
    "test_playbook_is_valid_yaml":      "Playbook is valid YAML",
    "test_playbook_has_tasks":          "Playbook contains tasks",
    "test_playbook_has_handler":        "Playbook contains SSH restart handler",
    "test_check_mode_succeeds":         "Dry run (--check) succeeds",
    "test_ssh_service_running":         "SSH service running on all nodes",
    "test_root_login_disabled":         "Root login disabled on all nodes",
    "test_password_auth_disabled":      "Password auth disabled on all nodes",
    "test_login_grace_time_set":        "LoginGraceTime set on all nodes",
    "test_playbook_is_idempotent":      "Playbook is idempotent (changed=0)",
}

# -- Reporter ---------------------------------------------------------------

# The phase-oriented summary is rendered by the shared `aria-reporter`
# pytest plugin (installed via requirements.txt); this file only declares
# the mission's phases + friendly objective names.
from aria_reporter import configure  # noqa: E402

configure(phases=PHASES, friendly=FRIENDLY, mission_id="1-2")
