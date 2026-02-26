#!/usr/bin/env bash
#
# Dotfiles installation script
# Creates symlinks from home directory to dotfiles repo
#
# Usage:
#   ./install.sh          # Install everything
#   ./install.sh agents   # Install only agent commands/skills (Claude + OpenCode)
#   ./install.sh claude   # Install only Claude agent commands/skills
#   ./install.sh opencode # Install only OpenCode agent commands/skills
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

# Register a plugin in installed_plugins.json
register_plugin() {
    local plugin_name="$1"
    local marketplace="$2"
    local install_path="$3"
    local version="$4"
    local plugins_file="$HOME/.claude/plugins/installed_plugins.json"
    
    # Create plugins directory if needed
    mkdir -p "$HOME/.claude/plugins"
    
    # Create initial file if it doesn't exist
    if [ ! -f "$plugins_file" ]; then
        echo '{"version":2,"plugins":{}}' > "$plugins_file"
    fi
    
    # Check if jq is available
    if ! command -v jq &> /dev/null; then
        warn "jq not found - cannot register plugin. Install jq and re-run."
        return 1
    fi
    
    local plugin_key="${plugin_name}@${marketplace}"
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")
    
    # Add or update the plugin entry
    local new_entry
    new_entry=$(jq -n \
        --arg scope "user" \
        --arg path "$install_path" \
        --arg ver "$version" \
        --arg ts "$timestamp" \
        '[{
            "scope": $scope,
            "installPath": $path,
            "version": $ver,
            "installedAt": $ts,
            "lastUpdated": $ts,
            "isLocal": true
        }]')
    
    # Update the plugins file
    jq --arg key "$plugin_key" --argjson entry "$new_entry" \
        '.plugins[$key] = $entry' "$plugins_file" > "${plugins_file}.tmp" && \
        mv "${plugins_file}.tmp" "$plugins_file"
    
    log "Registered plugin: $plugin_key"
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
    
    # Register the plugin so Claude Code discovers it
    register_plugin "global-skills" "custom" \
        "$HOME/.claude/plugins/cache/custom/global-skills/1.0.0" "1.0.0"
}

# Install OpenCode agent commands and skills
install_opencode_agents() {
    info "Setting up OpenCode commands..."
    mkdir -p "$HOME/.opencode/command"
    if [ -d "$DOTFILES_DIR/opencode/command" ]; then
        cp "$DOTFILES_DIR/opencode/command"/*.md "$HOME/.opencode/command/" 2>/dev/null && \
            log "Installed OpenCode slash commands" || \
            warn "No OpenCode commands to install"
    fi

    # Install OpenCode skills (symlink each skill directory)
    # OpenCode discovers skills from ~/.config/opencode/skills/<name>/SKILL.md
    info "Setting up OpenCode skills..."
    local skills_source="$DOTFILES_DIR/claude/plugins/global-skills/skills"
    local skills_target="$HOME/.config/opencode/skills"
    
    if [ -d "$skills_source" ]; then
        mkdir -p "$skills_target"
        
        # Symlink each skill directory individually
        for skill_dir in "$skills_source"/*/; do
            if [ -d "$skill_dir" ]; then
                local skill_name
                skill_name=$(basename "$skill_dir")
                create_symlink "$skill_dir" "$skills_target/$skill_name"
            fi
        done
        log "Installed OpenCode skills"
    else
        warn "No OpenCode skills found at $skills_source"
    fi
}

# Install pi coding agent config, extensions, agents, and skills
install_pi_agents() {
    local pi_source="$DOTFILES_DIR/pi"
    local pi_target="$HOME/.pi/agent"

    # Settings and keybindings
    info "Setting up pi configuration..."
    if [ -f "$pi_source/settings.json" ]; then
        create_symlink "$pi_source/settings.json" "$pi_target/settings.json"
        log "Installed pi settings.json"
    fi
    if [ -f "$pi_source/keybindings.json" ]; then
        create_symlink "$pi_source/keybindings.json" "$pi_target/keybindings.json"
        log "Installed pi keybindings.json"
    fi

    # Extensions (each subdirectory symlinked into ~/.pi/agent/extensions/)
    info "Setting up pi extensions..."
    local ext_source="$pi_source/extensions"
    local ext_target="$pi_target/extensions"

    if [ -d "$ext_source" ]; then
        mkdir -p "$ext_target"

        for ext_dir in "$ext_source"/*/; do
            if [ -d "$ext_dir" ]; then
                local ext_name
                ext_name=$(basename "$ext_dir")
                create_symlink "$ext_dir" "$ext_target/$ext_name"
            fi
        done

        # Run npm install for extensions with package.json
        for ext_dir in "$ext_target"/*/; do
            if [ -f "$ext_dir/package.json" ] && [ ! -d "$ext_dir/node_modules" ]; then
                info "Installing npm deps for $(basename "$ext_dir")..."
                (cd "$ext_dir" && npm install --silent 2>/dev/null) && \
                    log "Installed deps for $(basename "$ext_dir")" || \
                    warn "Failed to install deps for $(basename "$ext_dir")"
            fi
        done
        log "Installed pi extensions"
    fi

    # Agent definitions (*.md files into ~/.pi/agent/agents/)
    info "Setting up pi agent definitions..."
    local agents_source="$pi_source/agents"
    local agents_target="$pi_target/agents"

    if [ -d "$agents_source" ]; then
        mkdir -p "$agents_target"

        for agent_file in "$agents_source"/*.md; do
            if [ -f "$agent_file" ]; then
                local agent_name
                agent_name=$(basename "$agent_file")
                create_symlink "$agent_file" "$agents_target/$agent_name"
            fi
        done
        log "Installed pi agent definitions"
    else
        warn "No pi agents found at $agents_source"
    fi

    # Skills: pi/skills/ contains pi-specific overlays (real directories)
    # plus symlinks to base skills that don't have overlays.
    # This avoids duplicate-name warnings from pi.
    info "Setting up pi skills..."
    local skills_source="$pi_source/skills"
    local base_skills="$DOTFILES_DIR/claude/plugins/global-skills/skills"

    if [ -d "$base_skills" ]; then
        mkdir -p "$skills_source"

        # Symlink base skills that don't have pi overlays
        for skill_dir in "$base_skills"/*/; do
            if [ -d "$skill_dir" ]; then
                local skill_name
                skill_name=$(basename "$skill_dir")
                # Only symlink if no pi overlay exists (real directory, not a symlink)
                if [ ! -d "$skills_source/$skill_name" ] || [ -L "$skills_source/$skill_name" ]; then
                    create_symlink "$skill_dir" "$skills_source/$skill_name"
                else
                    info "Skipping $skill_name (pi overlay exists)"
                fi
            fi
        done
        log "Installed pi skills"
    else
        warn "No base skills found at $base_skills"
    fi

    # Scripts (bin/ directory → ~/bin/)
    info "Setting up lifecycle scripts..."
    local bin_source="$DOTFILES_DIR/bin"
    local bin_target="$HOME/bin"

    if [ -d "$bin_source" ]; then
        mkdir -p "$bin_target"
        for script in "$bin_source"/*; do
            if [ -f "$script" ]; then
                local script_name
                script_name=$(basename "$script")
                create_symlink "$script" "$bin_target/$script_name"
            fi
        done
        log "Installed scripts to ~/bin/"

        # Ensure ~/bin is on PATH
        if ! echo "$PATH" | grep -q "$HOME/bin"; then
            warn "~/bin is not on PATH. Add to your shell profile: export PATH=\"\$HOME/bin:\$PATH\""
        fi
    fi

    # Install declared npm packages (from settings.json packages array)
    info "Installing pi packages from settings.json..."
    if command -v pi &>/dev/null && [ -f "$pi_source/settings.json" ]; then
        local packages
        packages=$(python3 -c "
import json
with open('$pi_source/settings.json') as f:
    for p in json.load(f).get('packages', []):
        print(p)
" 2>/dev/null)

        while IFS= read -r pkg; do
            [ -z "$pkg" ] && continue
            if pi list 2>/dev/null | grep -q "$pkg"; then
                info "Package $pkg already installed"
            else
                pi install "$pkg" 2>/dev/null && \
                    log "Installed package $pkg" || \
                    warn "Failed to install package $pkg"
            fi
        done <<< "$packages"
    fi
}

# Handle agents-only install modes
case "$INSTALL_MODE" in
    agents)
        echo "Installing agent commands and skills only..."
        echo
        install_claude_agents
        install_opencode_agents
        install_pi_agents
        echo
        log "Agent installation complete!"
        info "Restart Claude Code / OpenCode / pi to load changes"
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
        echo "Installing OpenCode agent commands and skills..."
        echo
        install_opencode_agents
        echo
        log "OpenCode agent installation complete!"
        info "Restart OpenCode to load changes"
        exit 0
        ;;
    pi)
        echo "Installing pi agent definitions and skills..."
        echo
        install_pi_agents
        echo
        log "Pi agent installation complete!"
        info "Restart pi to load changes"
        exit 0
        ;;
    all)
        # Continue with full install below
        ;;
    *)
        echo "Usage: $0 [all|agents|claude|opencode|pi]"
        echo "  all      - Install everything (default)"
        echo "  agents   - Install only agent commands/skills (Claude + OpenCode + pi)"
        echo "  claude   - Install only Claude agent commands/skills"
        echo "  opencode - Install only OpenCode agent commands/skills"
        echo "  pi       - Install only pi agent definitions and skills"
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
