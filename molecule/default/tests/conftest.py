"""
ARIA Custom Test Reporter
Provides color-coded, phase-grouped output for mission verification.

Writes all output to stderr so check-work.sh can discard pytest's
default stdout while preserving our formatted display.
"""
import pytest
import sys

# -- ANSI escape codes ------------------------------------------------------

_COLOR = hasattr(sys.stderr, "isatty") and sys.stderr.isatty()


def _c(code):
    return code if _COLOR else ""


GREEN = _c("\033[32m")
RED = _c("\033[31m")
YELLOW = _c("\033[33m")
CYAN = _c("\033[36m")
DIM = _c("\033[2m")
BOLD = _c("\033[1m")
RESET = _c("\033[0m")

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


class _ARIAReporter:
    def __init__(self):
        self._current_class = None
        self.passed = 0
        self.failed = 0
        self.skipped = 0
        self._phase_results = {}
        self._current_phase_passed = True

    @staticmethod
    def _out(text):
        sys.stderr.write(text)
        sys.stderr.flush()

    def record(self, nodeid, outcome, longrepr):
        parts = nodeid.split("::")
        cls = parts[1] if len(parts) > 1 else ""
        test = parts[-1]

        num, label = PHASES.get(cls, ("?", "Unknown"))
        name = FRIENDLY.get(test, test)

        if cls != self._current_class:
            if self._current_class is not None:
                self._phase_results[self._current_class] = self._current_phase_passed
            self._current_phase_passed = True
            self._current_class = cls
            self._out(f"\n  {CYAN}{BOLD}Phase {num}: {label}{RESET}\n")

        if outcome != "passed":
            self._current_phase_passed = False

        if outcome == "passed":
            self.passed += 1
            self._out(f"    {GREEN}✓{RESET} {name}\n")
        elif outcome == "skipped":
            self.skipped += 1
            self._out(f"    {YELLOW}○{RESET} {DIM}{name} — skipped{RESET}\n")
        else:
            self.failed += 1
            hint = _extract_hint(longrepr)
            if hint:
                # Deficiency: expected failure, student hasn't done this yet
                self._out(f"    {YELLOW}✗{RESET} {name}\n")
                self._out(f"      {DIM}↳ {hint}{RESET}\n")
            else:
                # Error: unexpected failure (syntax error, connection issue)
                self._out(f"    {RED}✗{RESET} {name}\n")

    def summary(self):
        if self._current_class is not None:
            self._phase_results[self._current_class] = self._current_phase_passed

        total = self.passed + self.failed + self.skipped
        self._out(f"\n  {'─' * 44}\n")

        phases_complete = sum(1 for v in self._phase_results.values() if v)
        total_phases = len(PHASES)
        self._out(f"  {BOLD}Progress:{RESET} {phases_complete} of {total_phases} phases complete\n")

        parts = []
        if self.passed:
            parts.append(f"{GREEN}{self.passed} verified{RESET}")
        if self.failed:
            parts.append(f"{RED}{self.failed} deficient{RESET}")
        if self.skipped:
            parts.append(f"{YELLOW}{self.skipped} skipped{RESET}")
        self._out(
            f"  {BOLD}Results:{RESET} {' · '.join(parts)}"
            f"  {DIM}({total} checks){RESET}\n"
        )


def _extract_hint(longrepr):
    """Pull the ARIA: message from an assertion failure."""
    if longrepr is None:
        return None
    crash = getattr(longrepr, "reprcrash", None)
    if crash:
        msg = getattr(crash, "message", "")
        if "ARIA:" in msg:
            return msg.split("ARIA:", 1)[-1].strip()
    text = str(longrepr)
    if "ARIA:" in text:
        raw = text.split("ARIA:")[-1].splitlines()[0].strip()
        return raw.rstrip("'\"")
    return None


# -- Singleton instance -----------------------------------------------------

_reporter = _ARIAReporter()

# -- Pytest hooks -----------------------------------------------------------


@pytest.hookimpl(tryfirst=True)
def pytest_runtest_logreport(report):
    """Intercept results before the default reporter sees them."""
    if report.when == "call":
        _reporter.record(report.nodeid, report.outcome, report.longrepr)
        report.longrepr = None
    elif report.when == "setup" and report.skipped:
        _reporter.record(report.nodeid, "skipped", report.longrepr)
        report.longrepr = None


def pytest_report_teststatus(report, config):
    """Return empty strings so the default reporter prints nothing per-test."""
    if report.when == "call":
        return report.outcome, "", ""
    if report.when == "setup" and report.skipped:
        return "skipped", "", ""


def pytest_terminal_summary(terminalreporter, exitstatus, config):
    """Print our summary; clear stats to suppress the default summary."""
    _reporter.summary()
