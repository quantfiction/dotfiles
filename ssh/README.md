# SSH Configuration

This directory contains SSH config and public keys for multi-account Git setup.

## What's Included

- `config`: SSH configuration with host aliases for work and personal GitHub accounts
- `*.pub`: Public SSH keys (safe to share/commit)

**NOT included:** Private SSH keys (these stay only on your machines)

## SSH Host Aliases

Your SSH config defines two host aliases:

### Personal Account (quantfiction)
```bash
git clone git@github.com-quantfiction:username/repo.git
```
Uses: `~/.ssh/id_ed_quantfiction`

### Work Account (TIE)
```bash
git clone git@github.com-tie:company/repo.git
```
Uses: `~/.ssh/id_ed_tie`

## Setting Up SSH Keys on New Machines

### Option 1: Copy from existing machine

```bash
# On existing machine, copy private keys securely:
scp ~/.ssh/id_ed_quantfiction new-machine:~/.ssh/
scp ~/.ssh/id_ed_tie new-machine:~/.ssh/

# On new machine, set correct permissions:
chmod 600 ~/.ssh/id_ed_*
```

### Option 2: Generate new keys

If you don't have access to your old keys:

```bash
# Generate personal key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed_quantfiction -C "your-personal@email.com"

# Generate work key
ssh-keygen -t ed25519 -f ~/.ssh/id_ed_tie -C "your-work@email.com"

# Add to GitHub:
# 1. Copy public key: cat ~/.ssh/id_ed_quantfiction.pub
# 2. Add to GitHub: Settings → SSH Keys → New SSH Key
# 3. Repeat for work account
```

## Using the Right Account

### When cloning

Use the appropriate host alias:

```bash
# Personal repos
git clone git@github.com-quantfiction:yourusername/dotfiles.git

# Work repos
git clone git@github.com-tie:company/work-repo.git
```

### For existing repos

Check which remote URL is configured:
```bash
git remote -v
```

If it's using the wrong account, update it:
```bash
# Change to personal account
git remote set-url origin git@github.com-quantfiction:username/repo.git

# Change to work account
git remote set-url origin git@github.com-tie:company/repo.git
```

## Testing SSH Connection

```bash
# Test personal account
ssh -T git@github.com-quantfiction

# Test work account
ssh -T git@github.com-tie
```

You should see: "Hi username! You've successfully authenticated..."

## Troubleshooting

### Permission denied (publickey)

1. Check key exists: `ls -la ~/.ssh/id_ed_*`
2. Check permissions: `chmod 600 ~/.ssh/id_ed_*`
3. Check config: `cat ~/.ssh/config`
4. Test connection: `ssh -T git@github.com-quantfiction`

### Wrong account being used

Check which key SSH is using:
```bash
ssh -v git@github.com-quantfiction 2>&1 | grep "Offering"
```

Should show your quantfiction key being offered.

### Key not loaded

Add keys to ssh-agent:
```bash
eval "$(ssh-agent -s)"
ssh-add ~/.ssh/id_ed_quantfiction
ssh-add ~/.ssh/id_ed_tie
```
