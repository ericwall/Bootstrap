#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# Mac M1 Server — One-liner remote installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/ericwall/Bootstrap/main/install.sh | bash
#
# Or with explicit shell:
#   bash <(curl -fsSL https://raw.githubusercontent.com/ericwall/Bootstrap/main/install.sh)
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

REPO_URL="https://github.com/ericwall/Bootstrap.git"
INSTALL_DIR="${HOME}/Bootstrap"

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ── Pre-flight ───────────────────────────────────────────────────────────────
if [[ "$(uname -s)" != "Darwin" ]]; then
  error "This installer only runs on macOS."
fi

echo ""
echo -e "${BOLD}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BOLD}║        Mac M1 Server — Automated Provisioning Installer        ║${NC}"
echo -e "${BOLD}╚══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# ── 1. Xcode Command Line Tools (needed for git) ────────────────────────────
info "Checking for Xcode Command Line Tools…"
if xcode-select -p &>/dev/null; then
  success "Xcode Command Line Tools already installed."
else
  info "Installing Xcode Command Line Tools (a macOS dialog may appear)…"
  xcode-select --install

  # Wait for the GUI install to finish
  echo ""
  info "Please complete the Xcode CLT installation dialog."
  until xcode-select -p &>/dev/null; do
    sleep 5
  done
  success "Xcode Command Line Tools installed."
fi

# ── 2. Clone the repo ───────────────────────────────────────────────────────
if [[ -d "${INSTALL_DIR}/.git" ]]; then
  info "Repository already exists at ${INSTALL_DIR} — pulling latest…"
  git -C "${INSTALL_DIR}" pull --ff-only
  success "Repository updated."
else
  if [[ -d "${INSTALL_DIR}" ]]; then
    warn "Directory ${INSTALL_DIR} exists but is not a git repo. Backing up…"
    mv "${INSTALL_DIR}" "${INSTALL_DIR}.bak.$(date +%s)"
  fi
  info "Cloning ${REPO_URL} → ${INSTALL_DIR}…"
  git clone "${REPO_URL}" "${INSTALL_DIR}"
  success "Repository cloned."
fi

# ── 3. Run bootstrap ────────────────────────────────────────────────────────
info "Running bootstrap script…"
cd "${INSTALL_DIR}"
chmod +x bootstrap.sh
./bootstrap.sh

# ── 4. Next steps ────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Installation complete!                                        ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}║  Next steps:                                                   ║${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}║  1. cd ~/Bootstrap                                             ║${NC}"
echo -e "${GREEN}║  2. vim group_vars/all.yml          ${NC}# review config${GREEN}              ║${NC}"
echo -e "${GREEN}║  3. ansible-vault create group_vars/vault.yml                   ║${NC}"
echo -e "${GREEN}║     ${NC}→ set vault_vnc_password${GREEN}                                     ║${NC}"
echo -e "${GREEN}║  4. ansible-playbook playbook.yml \\                            ║${NC}"
echo -e "${GREEN}║       --ask-become-pass --ask-vault-pass                        ║${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
