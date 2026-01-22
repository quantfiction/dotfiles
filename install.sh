#!/usr/bin/env bash
#
# Dotfiles installation script
# Creates symlinks from home directory to dotfiles repo
#
# Usage:
#   ./install.sh          # Install everything
#   ./install.sh agents   # Install only agent commands/skills (Claude + OpenCode)
#   ./install.sh claude   # Install only Claude agent commands/skills
#   ./install.sh opencode # Install only OpenCode agent commands
#
set -euo pipefail

DOTFILES_DIR="$HOME/dotfiles"
INSTALL_MODE="${1:-all}"

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

# Install Claude agent commands and skills
install_claude_agents() {
    info "Setting up Claude Code commands..."
    mkdir -p "$HOME/.claude/commands"
    if [ -d "$DOTFILES_DIR/claude/commands" ]; then
        cp "$DOTFILES_DIR/claude/commands"/*.md "$HOME/.claude/commands/" 2>/dev/null && \
            log "Installed Claude slash commands" || \
            warn "No Claude commands to install"
    fi

    info "Setting up Claude Code skills..."
    mkdir -p "$HOME/.claude/plugins/cache/custom/global-skills"
    create_symlink "$DOTFILES_DIR/claude/plugins/global-skills" "$HOME/.claude/plugins/cache/custom/global-skills/1.0.0"
}

# Install OpenCode agent commands
install_opencode_agents() {
    info "Setting up OpenCode commands..."
    mkdir -p "$HOME/.opencode/command"
    if [ -d "$DOTFILES_DIR/opencode/command" ]; then
        cp "$DOTFILES_DIR/opencode/command"/*.md "$HOME/.opencode/command/" 2>/dev/null && \
            log "Installed OpenCode slash commands" || \
            warn "No OpenCode commands to install"
    fi
}

# Handle agents-only install modes
case "$INSTALL_MODE" in
    agents)
        echo "Installing agent commands and skills only..."
        echo
        install_claude_agents
        install_opencode_agents
        echo
        log "Agent installation complete!"
        info "Restart Claude Code / OpenCode to load changes"
        exit 0
        ;;
    claude)
        echo "Installing Claude agent commands and skills only..."
        echo
        install_claude_agents
        echo
        log "Claude agent installation complete!"
        info "Restart Claude Code to load changes"
        exit 0
        ;;
    opencode)
        echo "Installing OpenCode agent commands only..."
        echo
        install_opencode_agents
        echo
        log "OpenCode agent installation complete!"
        info "Restart OpenCode to load changes"
        exit 0
        ;;
    all)
        # Continue with full install below
        ;;
    *)
        echo "Usage: $0 [all|agents|claude|opencode]"
        echo "  all      - Install everything (default)"
        echo "  agents   - Install only agent commands/skills (Claude + OpenCode)"
        echo "  claude   - Install only Claude agent commands/skills"
        echo "  opencode - Install only OpenCode agent commands"
        exit 1
        ;;
esac

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

# SSH config
info "Setting up SSH configuration..."
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Copy SSH config
if [ -f "$DOTFILES_DIR/ssh/config" ]; then
    backup_if_exists "$HOME/.ssh/config"
    cp "$DOTFILES_DIR/ssh/config" "$HOME/.ssh/config"
    chmod 600 "$HOME/.ssh/config"
    log "Copied SSH config"
fi

# Copy public keys
for pubkey in "$DOTFILES_DIR/ssh"/*.pub; do
    if [ -f "$pubkey" ]; then
        filename=$(basename "$pubkey")
        cp "$pubkey" "$HOME/.ssh/$filename"
        chmod 644 "$HOME/.ssh/$filename"
        log "Copied public key: $filename"
    fi
done

# Check for private keys
warn "IMPORTANT: Private SSH keys are NOT in dotfiles (for security)"
warn "You must manually copy your private keys to ~/.ssh/"
warn "Required keys based on your SSH config:"
echo "  - ~/.ssh/id_ed_tie (work)"
echo "  - ~/.ssh/id_ed_quantfiction (personal)"
echo "  Set permissions: chmod 600 ~/.ssh/id_ed_*"
echo

# Claude hooks
info "Setting up Claude hooks..."
mkdir -p "$HOME/.claude/hooks"
if [ -f "$DOTFILES_DIR/claude/hooks/git_safety_guard.sh" ]; then
    cp "$DOTFILES_DIR/claude/hooks/git_safety_guard.sh" "$HOME/.claude/hooks/"
    chmod +x "$HOME/.claude/hooks/git_safety_guard.sh"
    log "Installed git_safety_guard.sh"
fi
if [ -f "$DOTFILES_DIR/claude/hooks/git_safety_guard.py" ]; then
    cp "$DOTFILES_DIR/claude/hooks/git_safety_guard.py" "$HOME/.claude/hooks/"
    chmod +x "$HOME/.claude/hooks/git_safety_guard.py"
    log "Installed git_safety_guard.py"
fi

# Claude scripts
info "Setting up Claude scripts..."
mkdir -p "$HOME/.claude/scripts"
if [ -f "$DOTFILES_DIR/claude/scripts/file-suggestion.sh" ]; then
    cp "$DOTFILES_DIR/claude/scripts/file-suggestion.sh" "$HOME/.claude/scripts/"
    chmod +x "$HOME/.claude/scripts/file-suggestion.sh"
    log "Installed file-suggestion.sh"
fi

# Agent commands and skills (Claude + OpenCode)
install_claude_agents
install_opencode_agents

# Claude settings template
if [ ! -f "$HOME/.claude/settings.json" ] && [ -f "$DOTFILES_DIR/claude/settings.json.template" ]; then
    warn "Claude settings.json not found"
    info "Copy template: cp ~/dotfiles/claude/settings.json.template ~/.claude/settings.json"
elif [ -f "$HOME/.claude/settings.json" ]; then
    log "Claude settings.json already exists (not overwriting)"
fi

echo
log "Dotfiles installation complete!"
echo
info "Next steps:"
echo "  1. Restart your shell or run: source ~/.bashrc"
echo "  2. Restart Claude Code to load plugins"
echo
