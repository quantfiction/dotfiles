# Write Beads
Convert a Technical Design Document into a BEADS.md file.

## What this does
- Decomposes a TDD into atomic implementation beads in bd-compatible markdown
- **Incorporates should-fix findings from DESIGN_REVIEW.md** into relevant beads
- Creates dependency graph (mermaid)
- Groups beads by priority (P0/P1/P2)
- Defines implementation phases with gates
- Generates a runnable "Add Dependencies" bash script using `bd dep add` (run after `bd create -f`)

## Usage
Provide the polished Technical Design Document.

Output goes to `docs/plans/<project>/BEADS.md` and MUST be directly importable via:
`bd create -f docs/plans/<project>/BEADS.md`

## CRITICAL: Consume Review Findings

Before decomposing, check for `docs/plans/<project>/DESIGN_REVIEW.md`:

1. **If DESIGN_REVIEW.md exists:**
   - Extract all `should-fix` findings (ignore `waived` and `minor`)
   - For each should-fix, identify which bead it maps to by matching:
     - Section references (e.g., "section:6.3" → bead for that component)
     - API endpoints (e.g., "api:GET /swarm/history" → API bead)
     - File paths (e.g., "file:src/lib/auth.ts" → relevant bead)
   - Add mapped should-fixes to the bead's **Implementation Notes** section
   - For cross-cutting should-fixes that don't map to a single bead, create a **HARDEN-01: Hardening** bead

2. **If no DESIGN_REVIEW.md exists:**
   - Proceed with TDD-only decomposition
   - Log warning: "No DESIGN_REVIEW.md found - should-fixes not incorporated"

## Should-Fix Integration Format

Add to relevant beads:
```markdown
### Implementation Notes
> **Should-fix from review:**
> - `design-review::performance::section:6.3`: isPidAlive() blocks event loop - use async fs.readFile()
> - `design-review::domain::section:6.3-macos`: Add macOS support via ps command
```

## CRITICAL FORMAT RULES

**`bd create -f` treats EVERY `## ` (H2) as a bead.** Common mistakes:

```markdown
# WRONG - Creates garbage beads:
---
schemaVersion: 1        <-- WRONG: No YAML frontmatter
---

## Summary              <-- WRONG: Creates bead "Summary"
## Dependency Graph     <-- WRONG: Creates bead "Dependency Graph"

# CORRECT:
# Project Name

**Summary:** Text here.

### Dependency Graph    <-- H3 is safe
\`\`\`mermaid
...
\`\`\`

---

## CORE-01: Title       <-- Only beads get H2
```

**DO NOT:**
- Add YAML frontmatter (`---` block at top)
- Use `## ` for anything except bead titles
- Use `bd update --blocked-by` (unsupported)

## Bead characteristics
- Single clear objective
- Self-contained with no missing context
- Explicit inputs/outputs
- Testable completion criteria
- Completable in < 30 minutes

## Verification
Run before finishing: `pnpm validate:plans --path docs/plans/<project>`

## Should-Fix Traceability Check
Before finalizing, verify:
- [ ] All non-waived should-fixes from DESIGN_REVIEW.md are mapped to beads
- [ ] Cross-cutting should-fixes have a HARDEN bead (if any)
- [ ] Each mapped should-fix appears in exactly one bead's Implementation Notes

## Next steps
1. `/bead-review` - QA review of beads
2. `/create-beads` - Import into bd
3. `/launch-swarm` - Start agent swarm
