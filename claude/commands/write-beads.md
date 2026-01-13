# Write Beads
Convert a Technical Design Document into a BEADS.md file.

## What this does
- Decomposes TDD into atomic implementation beads
- Creates dependency graph (mermaid)
- Groups beads by priority (P0/P1/P2)
- Defines implementation phases with gates
- Generates dependency script for bd import

## Usage
Provide the polished Technical Design Document. Output goes to `docs/plans/<project>/BEADS.md`.

## Bead characteristics
- Single clear objective
- Self-contained with no missing context
- Explicit inputs/outputs
- Testable completion criteria
- Completable in < 30 minutes

## Next steps
1. `/bead-review` - QA review of beads
2. `/create-beads` - Import into bd
3. `/launch-swarm` - Start agent swarm
