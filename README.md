# Mac M1 Server — Ansible Provisioning

Fully automated, idempotent provisioning for a **macOS Apple Silicon** (M1/M2/M3) headless server. One bootstrap script, one playbook — from bare metal to production.

---

## Overview

This project turns a fresh Mac into a hardened, observable server running:

| Layer | What it provisions |
|---|---|
| **base** | Hostname, timezone, system defaults, energy settings |
| **homebrew** | CLI tools, cask apps, dev languages |
| **ssh** | Hardened `sshd` with key-only auth |
| **firewall** | macOS Application Firewall (`pf` / `socketfilterfw`) |
| **remote_desktop** | VNC / Screen Sharing via macOS native APIs |
| **cloudflared** | Cloudflare Tunnel for zero-trust ingress |
| **tailscale** | Mesh VPN (optional) |
| **build_server** | Forgejo Actions runner for CI/CD |
| **ai_research** | Ollama + default models for local LLM inference |
| **imessage_relay** | BlueBubbles server for iMessage bridging |
| **observability** | Prometheus, Node Exporter, Grafana |
| **services** | nginx reverse proxy, LaunchDaemon orchestration |

---

## Prerequisites

- **Hardware**: Mac with Apple Silicon (M1, M2, M3, or later)
- **OS**: macOS Ventura 13.0+ (Sonoma / Sequoia recommended)
- **Account**: A local admin account (the playbook does **not** create users)
- **Network**: Internet access for Homebrew and package downloads

> [!NOTE]
> The bootstrap script handles installing Xcode Command Line Tools, Homebrew, and Ansible — you do **not** need to pre-install anything.

---

## Quick Start

### 1. Clone the repository

```bash
git clone <repo-url> ~/mac-server-ansible
cd ~/mac-server-ansible
```

### 2. Run the bootstrap script

```bash
chmod +x bootstrap.sh
./bootstrap.sh
```

This installs Xcode CLT → Homebrew → Ansible → Galaxy dependencies.

### 3. Customise variables

```bash
vim group_vars/all.yml
```

At minimum, review `hostname`, `computer_name`, `admin_user`, and `timezone`.

### 4. Create a vault for secrets

```bash
ansible-vault create group_vars/vault.yml
```

Add the following variables inside the vault:

```yaml
vault_vnc_password: "your-secure-vnc-password"
```

### 5. Run the playbook

```bash
# Full provisioning
ansible-playbook playbook.yml --ask-become-pass --ask-vault-pass

# Single role
ansible-playbook playbook.yml --tags ssh --ask-become-pass

# Dry-run
ansible-playbook playbook.yml --check --diff --ask-become-pass --ask-vault-pass
```

---

## Project Structure

```
mac-server-ansible/
├── ansible.cfg              # Ansible configuration
├── bootstrap.sh             # One-time setup script
├── playbook.yml             # Main playbook
├── requirements.yml         # Galaxy collections & roles
├── inventory/
│   └── hosts.yml            # Inventory (localhost)
├── group_vars/
│   ├── all.yml              # All variables (edit this)
│   └── vault.yml            # Encrypted secrets (create this)
└── roles/
    ├── base/                # System fundamentals
    ├── homebrew/            # Package management
    ├── ssh/                 # SSH hardening
    ├── firewall/            # macOS firewall
    ├── remote_desktop/      # VNC / Screen Sharing
    ├── cloudflared/         # Cloudflare Tunnel
    ├── tailscale/           # Tailscale mesh VPN
    ├── build_server/        # Forgejo CI runner
    ├── ai_research/         # Ollama LLM server
    ├── imessage_relay/      # BlueBubbles
    ├── observability/       # Prometheus + Grafana
    └── services/            # nginx, LaunchDaemon management
```

---

## Role Descriptions

### `base`
Sets hostname, computer name, timezone, energy-saver settings (prevent sleep, wake on network access), and macOS system defaults for a headless server.

### `homebrew`
Installs CLI packages (`homebrew_packages`), GUI cask apps (`homebrew_cask_packages`), and development languages/runtimes (`dev_languages`) via Homebrew.

### `ssh`
Hardens the SSH daemon: disables password auth, restricts to key-based login, configures the listen port, and generates a host key if missing.

### `firewall`
Enables the macOS Application Firewall, configures stealth mode, and opens only the ports required by enabled services.

### `remote_desktop`
Enables macOS Screen Sharing (VNC) for headless management. Sets the VNC password from the Ansible Vault.

### `cloudflared`
Installs and configures `cloudflared` as a LaunchAgent, creating a named Cloudflare Tunnel for zero-trust access to services without exposing ports.

### `tailscale`
Installs Tailscale via Homebrew cask and configures it to start at login. Only runs when `enable_tailscale: true`.

### `build_server`
Installs the Forgejo Actions runner, registers it against `forgejo_instance_url` with the specified labels, and creates a LaunchAgent for automatic startup.

### `ai_research`
Installs Ollama, starts the server, and pulls the models listed in `ollama_default_models` for local LLM inference on Apple Silicon.

### `imessage_relay`
Installs BlueBubbles server for iMessage bridging. Requires manual Firebase credential setup after the initial run.

### `observability`
Installs and configures Prometheus, Node Exporter, and Grafana with LaunchAgents. Sets up scrape targets and a default Grafana datasource.

### `services`
Installs and configures nginx as a reverse proxy for local services (Grafana, Ollama, BlueBubbles, etc.). Manages LaunchDaemon lifecycle.

---

## Variable Customisation Guide

All variables live in `group_vars/all.yml`. Here's what to change for common scenarios:

| Variable | Default | Notes |
|---|---|---|
| `hostname` | `m1max.ericwall.me` | FQDN set via `scutil` |
| `computer_name` | `m1max` | Friendly name in Finder / Bonjour |
| `timezone` | `America/Chicago` | Any valid `systemsetup -listtimezones` value |
| `admin_user` | `ericwall` | Must be an existing local admin |
| `ssh_port` | `22` | Change to a non-standard port for obscurity |
| `homebrew_packages` | *(see all.yml)* | Add/remove CLI tools as needed |
| `homebrew_cask_packages` | `[]` | Add GUI apps: `- firefox`, `- iterm2`, etc. |
| `dev_languages` | `python@3.12, node, go, rust` | Homebrew formulae for language runtimes |
| `enable_tailscale` | `false` | Set `true` to include the Tailscale role |
| `enable_cloudflared` | `true` | Cloudflare Tunnel for ingress |
| `cloudflared_tunnel_name` | `m1max` | Name registered in Cloudflare dashboard |
| `ollama_default_models` | *(see all.yml)* | Models pulled on first run |
| `grafana_port` | `3000` | Grafana web UI port |
| `nginx_enabled` | `true` | Master switch for the reverse proxy |

### Secrets (Ansible Vault)

Sensitive values are stored in `group_vars/vault.yml`:

```bash
# Create the vault file
ansible-vault create group_vars/vault.yml

# Edit later
ansible-vault edit group_vars/vault.yml
```

Required vault variables:

```yaml
vault_vnc_password: "your-vnc-password"
```

---

## Manual Post-Install Steps

Some services require one-time manual configuration that cannot be fully automated:

### 1. BlueBubbles — Firebase Credentials

BlueBubbles requires a Firebase project for push notifications:

1. Create a project at [Firebase Console](https://console.firebase.google.com/)
2. Download the `google-services.json` / `GoogleService-Info.plist`
3. Place credentials in the BlueBubbles data directory
4. Restart the BlueBubbles service

### 2. Forgejo Actions Runner — Registration Token

The runner needs a one-time registration token:

1. Log into your Forgejo instance at the configured URL
2. Go to **Site Administration → Actions → Runners**
3. Click **Create new runner** and copy the registration token
4. Run: `forgejo-runner register --instance <url> --token <token>`

### 3. Cloudflare Tunnel — Authentication

After `cloudflared` is installed, authenticate and create the tunnel:

```bash
cloudflared tunnel login
cloudflared tunnel create {{ cloudflared_tunnel_name }}
```

The credentials file will be saved to `~/.cloudflared/`. The role will configure the tunnel to start automatically after this initial setup.

### 4. Tailscale — Device Authorisation

If Tailscale is enabled, authenticate after the first run:

```bash
tailscale up
```

Follow the URL printed to authorise the device in your Tailscale admin console.

---

## Troubleshooting

### Homebrew permission errors

```bash
# Reset Homebrew permissions
sudo chown -R $(whoami) /opt/homebrew
```

### Ansible "Python interpreter" warnings

The inventory uses `ansible_python_interpreter: auto`. If you see warnings, pin it explicitly:

```yaml
# inventory/hosts.yml
ansible_python_interpreter: /opt/homebrew/bin/python3
```

### Role fails with "become" password prompt

Most roles avoid `become: true`, but system-level tasks (firewall, energy settings, sshd) require it. Always pass `--ask-become-pass`:

```bash
ansible-playbook playbook.yml --ask-become-pass
```

### VNC / Screen Sharing won't start

macOS requires Full Disk Access and Screen Recording permissions for remote desktop:

1. Open **System Settings → Privacy & Security**
2. Grant the appropriate permissions
3. Re-run the `remote_desktop` role

### Ollama model pull is slow

Large models (e.g., `codellama`) can be 4–8 GB. On first run, `ollama pull` may take a while. The task uses `async` with generous timeouts. If it times out, pull manually:

```bash
ollama pull codellama
```

### "Playbook hangs" on energy settings

The `systemsetup` commands require `sudo`. Ensure you passed `--ask-become-pass` or have passwordless `sudo` configured.

### Re-running is safe

All tasks are idempotent. Re-running the playbook will only change what has drifted from the desired state. Use `--check --diff` to preview changes before applying.

---

## License

MIT
