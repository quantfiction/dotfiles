# Dotfiles

Personal configuration files and development environment setup with integrated AI-assisted workflow automation.

## What's Included

- **Shell configs**: bashrc, profile, zshrc (Oh My Zsh with plugins)
- **Git config**: Multi-account setup with work/personal identities
- **SSH config**: Host aliases for work and personal GitHub accounts
- **Claude Code**:
  - **10 slash commands**: /ask-questions, /plan-polish, /write-beads, /bead-review, /create-beads, /launch-swarm, /review, /intake, /review-design, /research-plan
  - **12 global skills**: Complete workflow automation skills
  - **Git safety hooks**: Prevent destructive git/filesystem commands
  - **File suggestion script**: Custom fuzzy finder using rg + fzf
  - **Settings template**: Recommended Claude Code configuration
- **OpenCode**: Mirrored commands for OpenCode agent framework
- **Install script**: Automated symlink setup with backup

## Quick Start

### First-Time Setup

1. **Clone this repository:**
   ```bash
   git clone <your-repo-url> ~/dotfiles
   cd ~/dotfiles
   ```

2. **Update git config with your info:**
   ```bash
   # Edit git/gitconfig and replace placeholders:
   nano git/gitconfig
   # Change YOUR_NAME_HERE and YOUR_EMAIL_HERE
   ```

3. **Run the install script:**
   ```bash
   ./install.sh
   ```

4. **Restart your shell:**
   ```bash
   source ~/.bashrc
   # Or just open a new terminal
   ```

5. **Restart Claude Code** to load plugins

### On New Machines

Just run steps 1, 2, 3, 4, and 5 above. The install script handles everything automatically.

### Partial Installation

Install only specific components:
```bash
./install.sh agents   # Only Claude and OpenCode configs
./install.sh claude   # Only Claude Code configs
./install.sh opencode # Only OpenCode configs
```

## What the Install Script Does

- Backs up existing config files (creates `.backup.<timestamp>` files)
- Creates symlinks from `~/.bashrc`, `~/.gitconfig`, etc. to this repo
- Sets up Claude plugins in the correct location
- Registers global-skills plugin in `~/.claude/plugins/installed_plugins.json`
- Installs OpenCode commands to `~/.config/opencode/`
- Preserves your existing configs as backups before linking

## Directory Structure

```
dotfiles/
├── claude/
│   ├── commands/                   # 10 slash commands
│   │   ├── ask-questions.md
│   │   ├── bead-review.md
│   │   ├── create-beads.md
│   │   ├── intake.md
│   │   ├── launch-swarm.md
│   │   ├── plan-polish.md
│   │   ├── research-plan.md
│   │   ├── review.md
│   │   ├── review-design.md
│   │   └── write-beads.md
│   ├── hooks/
│   │   ├── git_safety_guard.sh     # Blocks destructive git commands
│   │   └── git_safety_guard.py     # Additional git safety checks
│   ├── plugins/
│   │   └── global-skills/          # Custom global skills plugin
│   │       ├── .claude-plugin/
│   │       └── skills/             # 12 workflow skills
│   │           ├── ask-questions-if-underspecified/
│   │           ├── bead-fix/
│   │           ├── bead-review/
│   │           ├── create-beads/
│   │           ├── intake/
│   │           ├── launch-swarm/
│   │           ├── plan-polish/
│   │           ├── research-plan/
│   │           ├── review/
│   │           ├── review-design/
│   │           ├── swarm-orchestrator/
│   │           └── write-beads/
│   ├── scripts/
│   │   └── file-suggestion.sh      # Custom file fuzzy finder
│   ├── settings.json.template      # Claude Code settings template
│   └── README.md                   # Claude Code documentation
├── git/
│   └── gitconfig                   # Git configuration
├── opencode/
│   └── commands/                   # OpenCode command mirrors
│       ├── ask-questions.md
│       ├── bead-review.md
│       ├── create-beads.md
│       ├── intake.md
│       ├── launch-swarm.md
│       ├── plan-polish.md
│       ├── research-plan.md
│       ├── review.md
│       ├── review-design.md
│       └── write-beads.md
├── ssh/
│   ├── config                      # SSH host aliases for multi-account
│   ├── *.pub                       # Public SSH keys (private keys NOT included)
│   └── README.md                   # SSH setup guide
├── shell/
│   ├── bashrc                      # Bash configuration
│   ├── profile                     # Shell profile
│   └── zshrc                       # Zsh configuration
├── install.sh                      # Installation script
├── .gitignore                      # Prevents committing secrets
└── README.md                       # This file
```

## Multi-Account Git Setup

This dotfiles repo is configured for multiple Git accounts (work and personal).

### Important: No Default Identity

**There is NO default git identity configured.** This forces you to explicitly set your identity per-repo, preventing accidental commits to the wrong account.

### SSH Host Aliases

Configured in `ssh/config`:
- `github.com-quantfiction` → Personal account
- `github.com-tie` → Work account

### Using the Right Account

**Personal repos**:
```bash
# Clone with personal host alias
git clone git@github.com-quantfiction:username/repo.git
cd repo

# Set personal identity (REQUIRED before first commit)
git personal

# Verify
git whoami  # Shows: Your Personal Name / your-personal@email.com
```

**Work repos**:
```bash
# Clone with work host alias
git clone git@github.com-tie:company/repo.git
cd repo

# Set work identity (REQUIRED before first commit)
git work

# Verify
git whoami  # Shows: Your Work Name / your-work@email.com
```

### What Happens If You Forget?

If you try to commit without setting an identity:
```bash
git commit -m "test"
# Error: Author identity unknown
# *** Please tell me who you are.
```

This is intentional! Just run `git personal` or `git work` and try again.

### Git Aliases

- `git whoami` - Show current git identity (errors if not set)
- `git personal` - Set personal identity in current repo
- `git work` - Set work identity in current repo
- `git st` - Status
- `git co` - Checkout
- `git br` - Branch
- `git ci` - Commit

See `git/gitconfig` for full list and to customize.

### First-Time Setup on New Machines

1. Copy your private SSH keys (see `ssh/README.md`)

2. Test SSH connections:
   ```bash
   ssh -T git@github.com-quantfiction  # Personal
   ssh -T git@github.com-tie           # Work
   ```

3. In each repo, set your identity before committing:
   ```bash
   git personal  # or git work
   ```

## Claude Code Configuration

This dotfiles repo includes custom Claude Code configuration for enhanced safety and productivity.

### Slash Commands

Ten easy-to-use slash commands available from any project:

| Command | Description |
|---------|-------------|
| `/ask-questions` | Clarify ambiguous requirements before implementing |
| `/intake` | Process and understand new project requirements |
| `/plan-polish` | Convert rough plans to Technical Design Documents |
| `/research-plan` | Route plans through targeted research to gather verified facts |
| `/review-design` | Review and critique technical designs |
| `/write-beads` | Convert TDDs into atomic tasks (beads) |
| `/bead-review` | QA/audit task decomposition |
| `/create-beads` | Import tasks into bd issue tracker |
| `/launch-swarm` | Launch parallel agent swarm for execution |
| `/review` | General code review |

Just type the command in Claude Code (e.g., `/ask-questions`) to use it.

### Global Skills

Twelve workflow and planning skills power the slash commands above:

| Skill | Purpose |
|-------|---------|
| `ask-questions-if-underspecified` | Prompts for clarification on ambiguous requests |
| `intake` | Initial requirement gathering and analysis |
| `plan-polish` | Refines rough ideas into structured TDDs |
| `research-plan` | Validates plans with targeted research |
| `review-design` | Technical design review and feedback |
| `write-beads` | Converts designs to atomic, implementable tasks |
| `bead-review` | Quality assurance for task decomposition |
| `bead-fix` | Repairs issues with task definitions |
| `create-beads` | Imports tasks to issue tracking system |
| `launch-swarm` | Orchestrates parallel agent execution |
| `swarm-orchestrator` | Manages multi-agent coordination |
| `review` | Code review automation |

See `claude/README.md` for detailed documentation of each skill.

### Workflow Pipeline

The skills support a structured development workflow:

```
Requirements → /intake
     ↓
Clarification → /ask-questions
     ↓
Research → /research-plan
     ↓
Design → /plan-polish
     ↓
Review → /review-design
     ↓
Tasks → /write-beads
     ↓
QA → /bead-review
     ↓
Import → /create-beads
     ↓
Execute → /launch-swarm
     ↓
Review → /review
```

### Git Safety Hooks

Two hooks prevent Claude from running destructive commands:

**Blocked:**
- `git reset --hard` / `git push --force` / `git clean -f`
- `git checkout -- <file>` / `git restore` / `git branch -D`
- `rm -rf` (except /tmp directories)

**Allowed:**
- `git clean -n` (dry run) / `git push --force-with-lease`
- `rm -rf /tmp/...` (temporary directories)

The hooks are installed automatically by `install.sh`.

### File Suggestion Script

Custom fuzzy finder for file suggestions using ripgrep + fzf.

**Requirements:**
```bash
sudo apt install ripgrep fzf jq
```

Automatically configured by the settings template.

### Settings Template

Copy and customize for your machine:

```bash
cp ~/dotfiles/claude/settings.json.template ~/.claude/settings.json
# Edit to add your MCP servers, adjust plugins, etc.
```

The template includes:
- File suggestion configuration
- Git safety hook setup
- Model preference (sonnet)
- Plugin recommendations

See `claude/README.md` for full details.

## OpenCode Integration

Commands are mirrored for the OpenCode agent framework in `opencode/commands/`. These are installed to `~/.config/opencode/` by the install script.

Use the same slash commands in OpenCode:
```
/ask-questions
/plan-polish
/write-beads
...
```

## Shell Configuration

### Zsh (Default)

Oh My Zsh with plugins:
- git, node, npm, z
- zsh-autosuggestions
- zsh-syntax-highlighting

Additional tools initialized:
- **zoxide**: Smart directory jumping
- **Atuin**: Enhanced command history
- **Starship**: Cross-shell prompt

### Aliases

```bash
cc='claude'           # Claude Code shortcut
cod='codex'           # Codex shortcut
gmi='gemini --yolo'   # Gemini shortcut
```

## Adding New Configs

1. **Copy config to dotfiles:**
   ```bash
   cp ~/.someconfig ~/dotfiles/category/someconfig
   ```

2. **Add symlink to install.sh:**
   ```bash
   # Edit install.sh and add:
   create_symlink "$DOTFILES_DIR/category/someconfig" "$HOME/.someconfig"
   ```

3. **Commit changes:**
   ```bash
   cd ~/dotfiles
   git add .
   git commit -m "Add someconfig"
   git push
   ```

4. **On other machines:**
   ```bash
   cd ~/dotfiles
   git pull
   ./install.sh
   ```

## Adding More Claude Skills

1. Create skill directory:
   ```bash
   mkdir -p ~/dotfiles/claude/plugins/global-skills/skills/my-skill
   ```

2. Create `SKILL.md` with your skill definition

3. Commit and reinstall:
   ```bash
   cd ~/dotfiles
   git add .
   git commit -m "Add my-skill"
   ./install.sh  # Refreshes symlinks
   ```

## Security Notes

The `.gitignore` file prevents committing:
- SSH private keys (all formats)
- API keys and secrets
- Shell history
- `.env` files
- Credentials and PEM files

**Never commit sensitive data!** If you need machine-specific secrets, use:
- Environment variables (not in dotfiles)
- Separate secrets manager
- Machine-local config files (add to .gitignore)

## Troubleshooting

### Symlinks not working

Check if symlinks are created correctly:
```bash
ls -la ~/.bashrc  # Should show -> ~/dotfiles/shell/bashrc
```

If broken, re-run install script:
```bash
cd ~/dotfiles
./install.sh
```

### Claude plugin not loading

1. Verify plugin is registered:
   ```bash
   cat ~/.claude/plugins/installed_plugins.json | jq .
   ```

2. Verify symlink exists:
   ```bash
   ls -la ~/.claude/plugins/cache/custom/global-skills/1.0.0
   ```

3. Restart Claude Code completely

4. Check plugin structure:
   ```bash
   ls ~/dotfiles/claude/plugins/global-skills/
   ```

### Git config not applied

1. Check if symlink exists:
   ```bash
   ls -la ~/.gitconfig
   ```

2. Verify git is using the config:
   ```bash
   git config --list --show-origin
   ```

### Backups created during install

The install script backs up existing files as:
```
~/.bashrc.backup.20260113_180000
```

To restore a backup:
```bash
mv ~/.bashrc.backup.20260113_180000 ~/.bashrc
```

## Maintenance

### Updating configs

Edit files in `~/dotfiles/`, not in `~/`:
```bash
# Wrong:
nano ~/.bashrc

# Right:
nano ~/dotfiles/shell/bashrc
```

Changes take effect immediately (configs are symlinked).

### Syncing across machines

```bash
# On machine 1:
cd ~/dotfiles
git add .
git commit -m "Update configs"
git push

# On machine 2:
cd ~/dotfiles
git pull
```

No need to reinstall unless you added new files.

## Publishing to GitHub

```bash
cd ~/dotfiles

# Create repo on GitHub first, then:
git remote add origin git@github.com:yourusername/dotfiles.git
git push -u origin main
```

Now other machines can clone:
```bash
git clone git@github.com:yourusername/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

## License

MIT License - Do whatever you want with these configs
