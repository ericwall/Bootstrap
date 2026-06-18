#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# bootstrap.sh — One-time setup for a fresh macOS Apple Silicon server
#
# Usage:
#   chmod +x bootstrap.sh
#   ./bootstrap.sh
# ─────────────────────────────────────────────────────────────────────────────
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOMEBREW_PREFIX="/opt/homebrew"

# ── Colours ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Colour

info()    { echo -e "${BLUE}[INFO]${NC}  $*"; }
success() { echo -e "${GREEN}[OK]${NC}    $*"; }
warn()    { echo -e "${YELLOW}[WARN]${NC}  $*"; }
error()   { echo -e "${RED}[ERROR]${NC} $*"; exit 1; }

# ── Pre-flight checks ───────────────────────────────────────────────────────
if [[ "$(uname -s)" != "Darwin" ]]; then
  error "This script only runs on macOS."
fi

ARCH="$(uname -m)"
if [[ "$ARCH" != "arm64" ]]; then
  warn "Detected architecture: $ARCH — this project targets Apple Silicon (arm64)."
fi

# ── 1. Xcode Command Line Tools ─────────────────────────────────────────────
info "Checking for Xcode Command Line Tools…"
if xcode-select -p &>/dev/null; then
  success "Xcode Command Line Tools already installed at $(xcode-select -p)"
else
  info "Installing Xcode Command Line Tools (a macOS dialog may appear)…"
  xcode-select --install

  # Wait for the installation to complete
  echo ""
  info "Waiting for Xcode Command Line Tools installation to finish…"
  info "Please complete the dialog that appeared, then press ENTER here."
  read -r -p "Press ENTER when the install is done… "

  if ! xcode-select -p &>/dev/null; then
    error "Xcode Command Line Tools installation failed. Please install manually and re-run."
  fi
  success "Xcode Command Line Tools installed."
fi

# ── 2. Homebrew ──────────────────────────────────────────────────────────────
info "Checking for Homebrew…"
if command -v brew &>/dev/null; then
  success "Homebrew already installed at $(command -v brew)"
else
  info "Installing Homebrew…"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Ensure Homebrew is on PATH for the rest of this script
  eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv)"
  success "Homebrew installed."
fi

# ── 3. Add Homebrew to ~/.zprofile (idempotent) ──────────────────────────────
ZPROFILE="${HOME}/.zprofile"
BREW_SHELLENV_LINE='eval "$(/opt/homebrew/bin/brew shellenv)"'

if [[ -f "$ZPROFILE" ]] && grep -qF "$BREW_SHELLENV_LINE" "$ZPROFILE"; then
  success "Homebrew PATH already configured in ${ZPROFILE}"
else
  info "Adding Homebrew to PATH in ${ZPROFILE}…"
  {
    echo ""
    echo "# Homebrew (added by mac-server-ansible bootstrap)"
    echo "$BREW_SHELLENV_LINE"
  } >> "$ZPROFILE"
  success "Homebrew PATH added to ${ZPROFILE}"
fi

# Make sure brew is available now
eval "$("${HOMEBREW_PREFIX}/bin/brew" shellenv)"

# ── 4. Install Ansible ──────────────────────────────────────────────────────
info "Checking for Ansible…"
if command -v ansible &>/dev/null; then
  success "Ansible already installed: $(ansible --version | head -1)"
else
  info "Installing Ansible via Homebrew…"
  brew install ansible
  success "Ansible installed: $(ansible --version | head -1)"
fi

# ── 5. Install Galaxy collections & roles ────────────────────────────────────
info "Installing Ansible Galaxy collections…"
ansible-galaxy collection install -r "${SCRIPT_DIR}/requirements.yml" --force
success "Galaxy collections installed."

info "Installing Ansible Galaxy roles…"
ansible-galaxy role install -r "${SCRIPT_DIR}/requirements.yml" --force
success "Galaxy roles installed."

# ── Done ─────────────────────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║  Bootstrap complete! Your Mac is ready for provisioning.        ║${NC}"
echo -e "${GREEN}╠══════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}║  1. Review / edit variables:                                   ║${NC}"
echo -e "${GREEN}║     ${NC}vim group_vars/all.yml${GREEN}                                      ║${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}║  2. Run the full playbook:                                     ║${NC}"
echo -e "${GREEN}║     ${NC}ansible-playbook playbook.yml${GREEN}                                ║${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}║  3. Or run a single role:                                      ║${NC}"
echo -e "${GREEN}║     ${NC}ansible-playbook playbook.yml --tags base${GREEN}                    ║${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}║  4. Dry-run (check mode):                                      ║${NC}"
echo -e "${GREEN}║     ${NC}ansible-playbook playbook.yml --check --diff${GREEN}                 ║${NC}"
echo -e "${GREEN}║                                                                ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════╝${NC}"
