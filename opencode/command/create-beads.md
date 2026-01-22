# Create Beads
Import a BEADS.md file into bd and set up dependencies.

## What this does
- Runs `bd create -f` to import beads from markdown
- Executes dependency script to link beads
- Syncs with git via `bd sync`
- Verifies creation with `bd list` and `bd ready`

## Usage
Provide path to BEADS.md file (e.g., `docs/plans/slack-integration/BEADS.md`).

## Prerequisites
- BEADS.md must exist and pass `/bead-review`
- bd CLI installed and configured
- Beads use `## ID: Title` format (H2 headers)

## Next step
Run `/launch-swarm <label>` to start agent swarm.
