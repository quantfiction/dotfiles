# Bead Fix
Apply fixes from review ledger to BEADS.md.

## What this does
- Reads open issues from `BEADS_LEDGER.md` (created by `/bead-review`)
- Mechanically applies required fixes to `BEADS.md`
- Handles global fixes (metadata, labels) and targeted fixes (specific beads)
- Does NOT update ledger status (that happens on next `/bead-review` pass)

## Usage
Run after `/bead-review` identifies blockers or should-fixes.

Required files:
1. `docs/plans/<project>/BEADS_LEDGER.md` - Must have OPEN issues
2. `docs/plans/<project>/BEADS.md` - The file to fix
3. `docs/plans/<project>/TECHNICAL_DESIGN.md` - Reference for fixes needing TDD content

## Workflow
1. `/bead-review` → identifies issues → creates ledger
2. `/bead-fix` → applies fixes from ledger
3. `/bead-review` → verifies fixes → updates ledger
4. Repeat until 0 blockers in two consecutive passes

## Output
Modified `BEADS.md` with fixes applied. Run `/bead-review` again to verify.
