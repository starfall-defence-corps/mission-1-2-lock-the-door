# Starfall Defence Corps Academy

## Mission 1.2: Lock the Door

> *"The SSH Root Fairy has visited again — root login enabled on every node. The digital equivalent of leaving your front door open with a sign saying 'COME IN.' Write your first OPORD (playbook) to lock down SSH fleet-wide."*

You are a cadet at the Starfall Defence Corps Academy. The fleet was catalogued in Mission 1.1, but the SSH Root Fairy has left every node wide open — root login enabled, password authentication on, login grace times at insecure defaults. Your mission: write an Ansible playbook to harden SSH across all fleet nodes.

## Prerequisites

- [Docker Desktop](https://www.docker.com/products/docker-desktop/) (with Docker Compose v2)
- [GNU Make](https://www.gnu.org/software/make/)
- [Ansible](https://docs.ansible.com/ansible/latest/installation_guide/) (`ansible-core`)
- Python 3.10+ (for test environment)
  - On Debian/Ubuntu: `sudo apt install python3-venv`
- Git

> **Windows users**: This mission requires a Linux environment. Install [WSL2](https://learn.microsoft.com/en-us/windows/wsl/install) and run all commands from within your WSL terminal. Docker Desktop should be configured to use the WSL2 backend.

## Quick Start

```bash
# 1. Clone (or fork) this repo
git clone <repo-url>
cd mission-1-2-lock-the-door

# 2. Start the fleet
make setup
```

3. **Read your orders**: [Mission Briefing](docs/BRIEFING.md)
4. **Complete the exercises**: [Exercises](docs/EXERCISES.md)
5. **Stuck?** [Hints & Troubleshooting](docs/HINTS.md)
6. **Track progress**: [Checklist](CHECKLIST.md)

## Lab Architecture

```
 Your Machine
+------------------------------------------+
|  workspace/                              |
|    ansible.cfg                           |
|    inventory/hosts.yml  (pre-configured) |
|    playbook.yml         (you complete)   |
|    .ssh/cadet_key       (auto-generated) |
|                                          |
|  Docker Network: 172.30.0.0/24           |
|  +------------+ +----------+ +----------+|
|  | sdc-web    | | sdc-db   | | sdc-comms||
|  | :2221      | | :2222    | | :2223    ||
|  | Ubuntu22.04| | Ubuntu   | | Ubuntu   ||
|  | systemd    | | systemd  | | systemd  ||
|  | SSH misconfigs present (starting state)|
|  +------------+ +----------+ +----------+|
+------------------------------------------+
```

## Available Commands

```
make help       Show available commands
make setup      Start the fleet (3 target nodes)
make test       Ask ARIA to verify your work
make reset      Destroy and rebuild all fleet nodes
make destroy    Tear down everything (containers, keys, venv)
make ssh-web    SSH into sdc-web (fleet web server)
make ssh-db     SSH into sdc-db (fleet database server)
make ssh-comms  SSH into sdc-comms (fleet comms relay)
```

## Mission Files

| File | Purpose |
|------|---------|
| [BRIEFING.md](docs/BRIEFING.md) | Mission briefing — **read this first** |
| [EXERCISES.md](docs/EXERCISES.md) | Step-by-step exercises (4 phases) |
| [HINTS.md](docs/HINTS.md) | Troubleshooting and hints |
| [CHECKLIST.md](CHECKLIST.md) | Progress tracker |

## ARIA Review (Pull Request Workflow)

When you open a pull request, **ARIA** (Automated Review & Intelligence Analyst) automatically reviews your submission:

1. GitHub Actions runs the deterministic tests (`pytest`)
2. Your playbook and test results are sent to an LLM
3. ARIA posts a qualitative review as a PR comment — covering structure, security, and recommendations

**Local testing** (`make test`) runs pytest only — fast, offline, no API key needed.

**PR review** requires an `ANTHROPIC_API_KEY` repo secret. To set up:
1. Get an API key from [console.anthropic.com](https://console.anthropic.com/)
2. In your fork: Settings > Secrets and variables > Actions > New repository secret
3. Name: `ANTHROPIC_API_KEY`, Value: your key

If no API key is configured, PR review runs tests only and skips the LLM feedback.

## Troubleshooting

**Containers won't start**: Ensure Docker Desktop is running. Check for port conflicts on 2221-2223.

**SSH connection refused**: Run `make setup` to ensure containers are running and SSH is ready.

**`make test` fails with "No module named pytest"**: Run `make setup` first — it creates the Python virtual environment automatically.

**Need a clean slate**: Run `make reset` to destroy and rebuild everything.

**Docker network conflict**: If you see "Pool overlaps with other one on this address space", another Docker network is using the 172.30.0.0/24 subnet. Stop conflicting containers or edit `.docker/docker-compose.yml` to use a different subnet.
