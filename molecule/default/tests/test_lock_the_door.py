"""
=== STARFALL DEFENCE CORPS ACADEMY ===
ARIA Automated Verification - Mission 1.2: Lock the Door
========================================================
"""
import os
import re
import subprocess
import yaml
import pytest


def _root_dir():
    """Return the mission root directory."""
    tests_dir = os.path.dirname(os.path.abspath(__file__))
    return os.path.abspath(os.path.join(tests_dir, "..", "..", ".."))


def _workspace_dir():
    return os.path.join(_root_dir(), "workspace")


def _playbook_path():
    return os.path.join(_workspace_dir(), "playbook.yml")


def _load_playbook():
    path = _playbook_path()
    if not os.path.isfile(path):
        return None
    with open(path) as f:
        return yaml.safe_load(f)


def _run_ansible(*args, **kwargs):
    """Run an ansible command from the workspace directory."""
    timeout = kwargs.pop("timeout", 60)
    result = subprocess.run(
        list(args),
        capture_output=True,
        text=True,
        timeout=timeout,
        cwd=_workspace_dir(),
    )
    return result


# -------------------------------------------------------------------
# Phase 1: Playbook structure
# -------------------------------------------------------------------

class TestPlaybookStructure:
    """ARIA verifies: Has the cadet written a valid OPORD?"""

    def test_playbook_exists(self):
        """Playbook file must exist at workspace/playbook.yml"""
        assert os.path.isfile(_playbook_path()), (
            "ARIA: No playbook detected at workspace/playbook.yml. "
            "Cadet, an operation without an OPORD is chaos. "
            "Create your playbook and try again."
        )

    def test_playbook_is_valid_yaml(self):
        """Playbook must be valid YAML"""
        path = _playbook_path()
        if not os.path.isfile(path):
            pytest.skip("Playbook does not exist yet")
        with open(path) as f:
            data = yaml.safe_load(f)
        assert data is not None, (
            "ARIA: Playbook is empty. A blank OPORD protects no one."
        )

    def test_playbook_has_tasks(self):
        """Playbook must contain actual tasks (not just TODO comments)"""
        data = _load_playbook()
        if data is None:
            pytest.skip("Playbook does not exist yet")
        assert isinstance(data, list) and len(data) > 0, (
            "ARIA: Playbook structure is invalid. "
            "Expected a list of plays."
        )
        play = data[0]
        tasks = play.get("tasks", [])
        real_tasks = [t for t in tasks if t]
        assert len(real_tasks) >= 3, (
            f"ARIA: Insufficient tasks in playbook. Found {len(real_tasks)} "
            f"task(s) — expected at least 3 (root login, password auth, "
            f"LoginGraceTime). Complete the TODO sections in your playbook."
        )

    def test_playbook_has_handler(self):
        """Playbook must contain an SSH restart handler"""
        data = _load_playbook()
        if data is None:
            pytest.skip("Playbook does not exist yet")
        play = data[0]
        handlers = play.get("handlers", [])
        real_handlers = [h for h in handlers if h]
        assert len(real_handlers) >= 1, (
            "ARIA: No handlers found in playbook. "
            "SSH configuration changes require a service restart. "
            "Add a handler that restarts the ssh service."
        )
        for h in real_handlers:
            service = h.get("ansible.builtin.service", h.get("service", {}))
            if isinstance(service, dict):
                svc_name = service.get("name", "")
                if svc_name in ("ssh", "sshd"):
                    return
        for h in real_handlers:
            if "ssh" in h.get("name", "").lower():
                return
        assert False, (
            "ARIA: Handler found but it does not appear to manage the SSH service. "
            "Ensure your handler restarts the 'ssh' service."
        )


# -------------------------------------------------------------------
# Phase 2: Dry run
# -------------------------------------------------------------------

class TestDryRun:
    """ARIA verifies: Does the playbook pass a dry run?"""

    def test_check_mode_succeeds(self):
        """ansible-playbook --check must succeed"""
        data = _load_playbook()
        if data is None:
            pytest.skip("Playbook does not exist yet")
        play = data[0]
        tasks = [t for t in play.get("tasks", []) if t]
        if len(tasks) < 3:
            pytest.skip("Playbook tasks not yet complete")

        result = _run_ansible(
            "ansible-playbook", "playbook.yml", "--check", "--diff",
        )
        assert result.returncode == 0, (
            "ARIA: Dry run failed. Your playbook has syntax or logic errors. "
            "Run 'ansible-playbook playbook.yml --check --diff' to see details."
        )


# -------------------------------------------------------------------
# Phase 3: SSH hardening applied
# -------------------------------------------------------------------

class TestSSHHardening:
    """ARIA verifies: Has the cadet locked down SSH?"""

    @pytest.fixture(autouse=True)
    def _require_playbook_run(self):
        """Skip if playbook hasn't been applied yet."""
        data = _load_playbook()
        if data is None:
            pytest.skip("Playbook does not exist yet")
        play = data[0]
        tasks = [t for t in play.get("tasks", []) if t]
        if len(tasks) < 3:
            pytest.skip("Playbook tasks not yet complete")

    def _check_sshd_config(self, pattern, directive_name):
        """Check that a directive is set correctly on all nodes."""
        result = _run_ansible(
            "ansible", "all", "-m", "shell",
            "-a", f"grep -E '^{pattern}' /etc/ssh/sshd_config",
        )
        # Identify which nodes failed
        failed_nodes = []
        for host in ["sdc-web", "sdc-db", "sdc-comms"]:
            if host not in result.stdout:
                failed_nodes.append(host)
            elif f"{host} | FAILED" in result.stdout:
                failed_nodes.append(host)
        assert result.returncode == 0, (
            f"ARIA: '{directive_name}' not found on: "
            f"{', '.join(failed_nodes) if failed_nodes else 'all nodes'}. "
            f"Run your playbook, then verify with: "
            f"ansible all -m shell -a \"grep {directive_name.split()[0]} /etc/ssh/sshd_config\""
        )

    def test_root_login_disabled(self):
        """PermitRootLogin must be set to 'no' on all nodes"""
        self._check_sshd_config(
            r"PermitRootLogin\s+no",
            "PermitRootLogin no",
        )

    def test_password_auth_disabled(self):
        """PasswordAuthentication must be set to 'no' on all nodes"""
        self._check_sshd_config(
            r"PasswordAuthentication\s+no",
            "PasswordAuthentication no",
        )

    def test_login_grace_time_set(self):
        """LoginGraceTime must be set to 30 on all nodes"""
        self._check_sshd_config(
            r"LoginGraceTime\s+30",
            "LoginGraceTime 30",
        )


# -------------------------------------------------------------------
# Phase 4: Idempotency
# -------------------------------------------------------------------

class TestIdempotency:
    """ARIA verifies: Is the playbook idempotent?"""

    def test_playbook_is_idempotent(self):
        """Running the playbook a second time must show changed=0"""
        data = _load_playbook()
        if data is None:
            pytest.skip("Playbook does not exist yet")
        play = data[0]
        tasks = [t for t in play.get("tasks", []) if t]
        if len(tasks) < 3:
            pytest.skip("Playbook tasks not yet complete")

        first_run = _run_ansible(
            "ansible-playbook", "playbook.yml",
        )
        if first_run.returncode != 0:
            pytest.skip(
                "Playbook failed on first run — fix errors before testing idempotency"
            )

        second_run = _run_ansible(
            "ansible-playbook", "playbook.yml",
        )
        assert second_run.returncode == 0, (
            "ARIA: Playbook failed on second run. "
            "Fix the errors reported by 'ansible-playbook playbook.yml'."
        )
        changed_match = re.findall(r"changed=(\d+)", second_run.stdout)
        total_changed = sum(int(c) for c in changed_match)
        assert total_changed == 0, (
            f"ARIA: Idempotency failure. Second playbook run changed "
            f"{total_changed} task(s). A well-written playbook should make "
            f"no changes when run against an already-configured system. "
            f"Check your lineinfile regexp and line parameters."
        )
