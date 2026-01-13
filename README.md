# Dotfiles

Personal configuration files and development environment setup.

## What's Included

- **Shell configs**: bashrc, profile, zshrc
- **Git config**: Multi-account setup with work/personal identities
- **SSH config**: Host aliases for work and personal GitHub accounts
- **Claude plugins**: Custom global skills for Claude Code
- **Install script**: Automated symlink setup

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

## What the Install Script Does

- Backs up existing config files (creates `.backup.<timestamp>` files)
- Creates symlinks from `~/.bashrc`, `~/.gitconfig`, etc. to this repo
- Sets up Claude plugins in the correct location
- Preserves your existing configs as backups before linking

## Directory Structure

```
dotfiles/
├── claude/
│   └── plugins/
│       └── global-skills/          # Custom Claude Code plugins
│           ├── .claude-plugin/
│           └── skills/
│               └── ask-questions-if-underspecified/
├── git/
│   └── gitconfig                   # Git configuration
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

### Default Configuration

- **Default account**: Personal (quantfiction)
- **SSH host aliases**: Configured in `ssh/config`
  - `github.com-quantfiction` → Personal account
  - `github.com-tie` → Work account

### Using the Right Account

**Personal repos** (default):
```bash
# Clone normally
git clone git@github.com-quantfiction:username/repo.git

# Git identity already configured (personal email/name)
git whoami  # Check current identity
```

**Work repos**:
```bash
# Clone using work host alias
git clone git@github.com-tie:company/repo.git

# Switch to work identity
cd repo
git work  # Sets work email/name for this repo only

# Verify
git whoami
```

### Git Aliases

- `git whoami` - Show current git identity (name and email)
- `git work` - Switch current repo to work identity
- `git st` - Status
- `git co` - Checkout
- `git br` - Branch
- `git ci` - Commit

See `git/gitconfig` for full list and to customize.

### First-Time Git Setup

1. Edit `git/gitconfig` and replace placeholders:
   - `YOUR_NAME_HERE` → Your actual name
   - `YOUR_PERSONAL_EMAIL_HERE` → Your personal email
   - `YOUR_WORK_NAME_HERE` → Your work name (if different)
   - `YOUR_WORK_EMAIL_HERE` → Your work email

2. Copy your private SSH keys to new machines (see `ssh/README.md`)

3. Test SSH connections:
   ```bash
   ssh -T git@github.com-quantfiction  # Personal
   ssh -T git@github.com-tie           # Work
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

## Claude Global Skills

Custom Claude Code skills in `claude/plugins/global-skills/`:

- **ask-questions-if-underspecified**: Prompts for clarification when user requests are ambiguous

To use: `/ask-questions-if-underspecified`

### Adding More Claude Skills

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
- SSH keys and credentials
- API keys and secrets
- Shell history
- `.env` files

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

1. Verify symlink exists:
   ```bash
   ls -la ~/.claude/plugins/cache/custom/global-skills/1.0.0
   ```

2. Restart Claude Code completely

3. Check plugin structure:
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
