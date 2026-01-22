# Write Beads
Convert a Technical Design Document into a BEADS.md file.

## What this does
- Decomposes TDD into atomic implementation beads
- **Incorporates should-fix findings from DESIGN_REVIEW.md** into relevant beads
- Creates dependency graph (mermaid)
- Groups beads by priority (P0/P1/P2)
- Defines implementation phases with gates
- Generates dependency script for bd import

## Usage
Provide the polished Technical Design Document. Output goes to `docs/plans/<project>/BEADS.md`.

## CRITICAL: Consume Review Findings

Before decomposing, check for `docs/plans/<project>/DESIGN_REVIEW.md`:

1. **If DESIGN_REVIEW.md exists:**
   - Extract all `should-fix` findings (ignore `waived` and `minor`)
   - Map each to relevant bead by matching section/API/file references
   - Add to bead's **Implementation Notes** section
   - Cross-cutting should-fixes that don't map to a single bead → **HARDEN-01** bead

2. **If no DESIGN_REVIEW.md exists:**
   - Proceed with TDD-only decomposition
   - Log warning: "No DESIGN_REVIEW.md found - should-fixes not incorporated"

## Bead characteristics
- Single clear objective
- Self-contained with no missing context
- Explicit inputs/outputs
- Testable completion criteria
- Completable in < 30 minutes

## Verification
- [ ] All non-waived should-fixes mapped to beads or HARDEN bead
- [ ] Cross-cutting should-fixes have a dedicated HARDEN bead (if any)

## Next steps
1. `/bead-review` - QA review of beads
2. `/create-beads` - Import into bd
3. `/launch-swarm` - Start agent swarm
