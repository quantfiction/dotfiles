# Launch Swarm
Launch parallel agents to work on beads with a specific label.

## What this does
- Verifies beads exist and are ready (no blockers)
- Sends `bead_swarm` template to all tmux panes
- Confirms execution by pressing ENTER in each pane
- Provides monitoring commands

## Usage
Provide the bead label (e.g., `slack-integration`).

## Prerequisites
- Beads imported via `/create-beads` with consistent label
- tmux session exists (default: `mindhive`)
- ntm (NeoTmux Manager) installed and configured
- At least one bead in `ready` status

## Monitoring commands
```bash
# Bead progress
bd list -l <label> --json | jq 'group_by(.status) | map({status: .[0].status, count: length})'

# Agent activity
ntm activity mindhive

# Ready beads
bd ready -l <label>
```
