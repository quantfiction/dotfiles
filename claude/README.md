# Claude Code Configuration

This directory contains Claude Code configuration files, hooks, scripts, and custom plugins.

## Structure

```
claude/
├── hooks/
│   ├── git_safety_guard.sh     # Blocks destructive git commands
│   └── git_safety_guard.py     # Additional git safety checks
├── plugins/
│   └── global-skills/          # Custom global skills plugin
│       ├── .claude-plugin/
│       └── skills/
│           ├── ask-questions-if-underspecified/
│           ├── plan-polish/
│           ├── write-beads/
│           ├── bead-review/
│           ├── create-beads/
│           └── launch-swarm/
├── scripts/
│   └── file-suggestion.sh      # Custom file fuzzy finder
├── settings.json.template      # Settings template (copy to ~/.claude/settings.json)
└── README.md                   # This file
```

## Global Skills

Custom workflow and planning skills available from any repository:

### ask-questions-if-underspecified
Clarify requirements before implementing by detecting ambiguity and asking structured questions.

**Usage:** `/ask-questions-if-underspecified`

### plan-polish
Convert rough plans into implementation-grade Technical Design Documents for autonomous agent execution.

**Usage:** `/plan-polish`

### write-beads
Convert Technical Design Documents into BEADS.md files with atomic implementation tasks.

**Usage:** `/write-beads`

### bead-review
QA/adversarial audit of bead decomposition for autonomous agent execution.

**Usage:** `/bead-review`

### create-beads
Import BEADS.md files into bd issue tracker and set up dependencies.

**Usage:** `/create-beads`

### launch-swarm
Launch parallel agent swarm to work on beads with specific labels.

**Usage:** `/launch-swarm`

## Hooks

### Git Safety Guards

Two complementary hooks that prevent Claude from running destructive git/filesystem commands:

**Blocks:**
- `git reset --hard` (destroys uncommitted changes)
- `git push --force` (rewrites remote history)
- `git clean -f` (permanently removes untracked files)
- `git checkout -- <file>` (discards changes)
- `git restore` (discards changes)
- `git branch -D` (force deletes branch)
- `git stash drop/clear` (deletes stashed changes)
- `rm -rf` (except in /tmp directories)

**Allows:**
- `git clean -n` (dry run)
- `git push --force-with-lease` (safer force push)
- `git checkout -b` (create new branch)
- `rm -rf /tmp/...` (temporary directories)

The hooks work by intercepting `Bash` tool calls before execution and blocking dangerous commands with a helpful error message.

## Scripts

### file-suggestion.sh

Custom file fuzzy finder that Claude uses to suggest files when you reference them.

**Features:**
- Uses ripgrep (rg) for fast file listing
- Uses fzf for fuzzy matching
- Respects .gitignore
- Follows symlinks
- Includes hidden files

**Requirements:**
- `rg` (ripgrep)
- `fzf`
- `jq`

Install on Ubuntu/Debian:
```bash
sudo apt install ripgrep fzf jq
```

## Settings Template

`settings.json.template` contains recommended settings for Claude Code.

### Setup

1. Copy template to your Claude config:
   ```bash
   cp ~/dotfiles/claude/settings.json.template ~/.claude/settings.json
   ```

2. Edit `~/.claude/settings.json` and customize:
   - Add your MCP servers (remove the `_comment` and `_example` fields)
   - Adjust enabled plugins as needed
   - Change model preference if desired

3. The install script will automatically set up hooks and scripts paths.

### What's Configured

- **File suggestion**: Uses custom fuzzy finder script
- **Model**: Default to Sonnet (change to "opus" or "haiku" if preferred)
- **Hooks**: Git safety guards on PreToolUse
- **Plugins**: beads and mgrep enabled by default

### Machine-Specific Settings

Some settings are machine-specific and should be configured locally:

- **MCP servers**: URLs and auth tokens vary per machine
- **Plugins**: May want different plugins enabled in different environments
- **SessionStart/PreCompact hooks**: Project-specific (like "bd prime" for beads)

For machine-specific settings, create `~/.claude/settings.local.json` which will override settings.json (if your Claude Code version supports it).

## Installation

The main `install.sh` script handles installation of all Claude-related files:

- Symlinks global-skills plugin to `~/.claude/plugins/cache/custom/global-skills/1.0.0`
- Copies hooks to `~/.claude/hooks/`
- Copies scripts to `~/.claude/scripts/`
- Optionally installs settings.json template

## Troubleshooting

### Skills not loading

1. Check plugin is symlinked:
   ```bash
   ls -la ~/.claude/plugins/cache/custom/global-skills/1.0.0
   ```

2. Restart Claude Code completely

3. Verify skill structure:
   ```bash
   ls ~/dotfiles/claude/plugins/global-skills/skills/
   ```

### Git safety hooks blocking legitimate commands

If a hook incorrectly blocks a safe command, you have options:

1. Run the command manually in your terminal (recommended for destructive operations)
2. Ask Claude to suggest a safer alternative
3. Modify the hook patterns in `~/dotfiles/claude/hooks/git_safety_guard.sh`

The hooks are intentionally conservative to prevent data loss.

### File suggestion not working

Check requirements are installed:
```bash
which rg && which fzf && which jq
```

If missing:
```bash
sudo apt install ripgrep fzf jq
```

## Customization

### Adding New Skills

1. Create skill directory:
   ```bash
   mkdir -p ~/dotfiles/claude/plugins/global-skills/skills/my-skill
   ```

2. Create `SKILL.md` with frontmatter:
   ```markdown
   ---
   name: my-skill
   description: What this skill does
   ---

   # My Skill

   [Skill instructions here...]
   ```

3. Commit and push:
   ```bash
   cd ~/dotfiles
   git add .
   git commit -m "Add my-skill"
   git push
   ```

4. On other machines:
   ```bash
   cd ~/dotfiles
   git pull
   ```

The symlink will automatically make the new skill available.

### Modifying Hooks

Edit hooks in `~/dotfiles/claude/hooks/`, then:

```bash
cd ~/dotfiles
git add claude/hooks/
git commit -m "Update git safety guards"
git push
```

On other machines, pull changes and the hooks will be updated automatically (they're copied, not symlinked).

## References

- [Claude Code Documentation](https://docs.anthropic.com/claude/docs/claude-code)
- [Claude Skills Documentation](https://docs.anthropic.com/claude/docs/skills)
- [Claude Hooks Documentation](https://docs.anthropic.com/claude/docs/hooks)
