#!/usr/bin/env bash
#
# Dotfiles installation script
# Creates symlinks from home directory to dotfiles repo
#
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[+]${NC} $1"; }
warn() { echo -e "${YELLOW}[!]${NC} $1"; }
info() { echo -e "${BLUE}[i]${NC} $1"; }

# Backup existing file if it's not a symlink
backup_if_exists() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        local backup="${target}.backup.$(date +%Y%m%d_%H%M%S)"
        warn "Backing up existing $target to $backup"
        mv "$target" "$backup"
    elif [ -L "$target" ]; then
        warn "Removing existing symlink $target"
        rm "$target"
    fi
}

# Create symlink with backup
create_symlink() {
    local source="$1"
    local target="$2"

    if [ ! -e "$source" ]; then
        warn "Source $source does not exist, skipping"
        return
    fi

    backup_if_exists "$target"

    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"

    ln -sf "$source" "$target"
    log "Linked $target → $source"
}

echo "Installing dotfiles from $DOTFILES_DIR"
echo

# Shell configs
info "Setting up shell configuration..."
create_symlink "$DOTFILES_DIR/shell/bashrc" "$HOME/.bashrc"
create_symlink "$DOTFILES_DIR/shell/profile" "$HOME/.profile"
create_symlink "$DOTFILES_DIR/shell/zshrc" "$HOME/.zshrc"

# Git config
info "Setting up git configuration..."
create_symlink "$DOTFILES_DIR/git/gitconfig" "$HOME/.gitconfig"

# Claude plugins
info "Setting up Claude plugins..."
mkdir -p "$HOME/.claude/plugins/cache/custom/global-skills"
create_symlink "$DOTFILES_DIR/claude/plugins/global-skills" "$HOME/.claude/plugins/cache/custom/global-skills/1.0.0"

echo
log "Dotfiles installation complete!"
echo
info "Next steps:"
echo "  1. Restart your shell or run: source ~/.bashrc"
echo "  2. Restart Claude Code to load plugins"
echo
