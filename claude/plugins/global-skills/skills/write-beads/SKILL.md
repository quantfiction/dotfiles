---
name: write-beads
description: Convert a Technical Design Document into a BEADS.md file for agent implementation
---

# Write Beads

Convert a Technical Design Document (TDD) into a BEADS.md markdown file containing atomic implementation beads.

**This skill outputs a markdown file only.** To create actual beads in bd, use `/create-beads` after review.

## When to use

Use when you have:
- A polished Technical Design Document from Stage 2
- Need to break down work for autonomous coding agents
- Want to create trackable, independently-executable tasks

## Role

You are a task decomposition engine preparing work for autonomous coding agents.

## Bead definition

A bead is the smallest unit of work that:
- Has a single clear objective (one responsibility)
- Is self-contained (no missing context)
- Has explicit inputs/outputs
- Has testable completion criteria
- Can be completed in one focused session (target < 30 minutes)

## Rules

- Prefer *more beads* over fewer
- If a bead depends on a decision, create a separate **DECISION** bead
- Use dependencies to express ordering; do not assume strict sequence
- Assume agents will not infer context beyond what is written

## Output Format

Output a SINGLE markdown file (`BEADS.md`) that can be directly imported into bd:

```bash
bd create -f docs/plans/<project>/BEADS.md
```

### File Structure

The output file MUST have these sections in order:

1. **Header** - Project name and link to TDD
2. **Dependency Graph** - Mermaid diagram showing relationships
3. **Summary Tables** - Beads grouped by priority with dependencies
4. **Dependency Commands** - Ready-to-run `bd dep add` commands
5. **Full Bead Definitions** - One `## ` section per bead

### Bead Format (bd-compatible)

Each bead uses `## ` for the title (H2), and `### ` for sections (H3):

```markdown
## {ID}: {Title}

### Priority
P0

### Type
task

### Labels
{project-label}, {phase-label}

### Description

**Context:**
Why this exists, what already exists, what this creates/modifies.

**Specification:**
Exact requirements, inputs, outputs, interface contracts, error handling.

**Files:**
- Create: {filepaths}
- Modify: {filepaths}
- Reference: {filepaths}

**Common Failure Modes:**
What implementers commonly get wrong.

### Acceptance Criteria
- [ ] Specific verifiable condition
- [ ] Passes: {test command}

```

**CRITICAL FORMAT RULES**:
1. Do NOT use `## ` (H2) anywhere inside the Description - use `**Bold:**` for sub-headers
2. Do NOT include a `### Deps` or `### Dependencies` section - bd cannot resolve symbolic deps during batch creation
3. Dependencies are added AFTER creation using `bd dep add`

### Dependency Script Section

After the summary tables, include a **complete executable script** that adds all dependencies.

bd cannot resolve symbolic dependencies during batch creation, so dependencies MUST be added after beads are created.

```markdown
## Add Dependencies

After creating beads, run this script to add all dependencies:

\`\`\`bash
#!/bin/bash
# Auto-generated dependency script for {project-name}
# Usage: bd create -f BEADS.md && bash add-deps.sh

set -e

# Get bead ID mapping
echo "Fetching bead IDs..."
declare -A IDS
while IFS=': ' read -r key value; do
  IDS[$key]=$value
done < <(bd list -l {label} --json | jq -r '.[] | "\(.title | split(":")[0]): \(.id)"')

# Add dependencies (child depends on parent)
bd dep add ${IDS[CHILD-01]} ${IDS[PARENT-01]}
bd dep add ${IDS[CHILD-02]} ${IDS[PARENT-01]}
bd dep add ${IDS[CHILD-02]} ${IDS[PARENT-02]}
# ... continue for all dependencies

echo "Dependencies added. Syncing..."
bd sync
\`\`\`
```

**The script MUST be complete and runnable** - include every dependency from the graph.

## ID Conventions

Use category prefixes:
- `SETUP-NN` - Foundation/configuration
- `SCHEMA-NN` - Database schemas/migrations
- `CORE-NN` - Core logic/utilities
- `JOB-NN` - Background jobs
- `API-NN` - API endpoints
- `UI-NN` - User interface
- `TEST-NN` - Tests
- `INTEG-NN` - Integration work
- `DOCS-NN` - Documentation
- `CLEAN-NN` - Cleanup/refactoring
- `DECISION-NN` - Decisions requiring input

## Priority Guidelines

- **P0**: Blocks critical path, must be done first
- **P1**: Core functionality, MVP requirements
- **P2**: Polish, cleanup, nice-to-have

## Phase Labels

Assign phase labels based on category:
- `phase-0`: SETUP, SCHEMA (foundation)
- `phase-1`: CORE (infrastructure)
- `phase-2`: JOB (background processing)
- `phase-3`: API (endpoints)
- `phase-4`: UI (user interface)
- `phase-5`: TEST (testing)
- `phase-6`: CLEAN, DOCS (polish)

## Ordering Heuristics

- Foundation/setup before core logic
- Core logic before integrations
- Tests alongside or immediately after the behavior they validate
- Integration/system beads last

## Example Output

```markdown
# Project Name - Implementation Beads

Derived from [TECHNICAL_DESIGN.md](./TECHNICAL_DESIGN.md).

## Dependency Graph

\`\`\`mermaid
graph TD
    SETUP-01 --> CORE-01
    CORE-01 --> API-01
    API-01 --> UI-01
\`\`\`

## Summary

| ID | Title | Priority | Dependencies |
|----|-------|----------|--------------|
| SETUP-01 | Add provider constant | P0 | - |
| CORE-01 | Implement client | P0 | SETUP-01 |
| API-01 | Create endpoint | P1 | CORE-01 |
| UI-01 | Build picker UI | P1 | API-01 |

## Dependency Commands

After `bd create -f BEADS.md`, add dependencies:

\`\`\`bash
bd list -l my-project --json | jq -r '.[] | "\(.title | split(":")[0]): \(.id)"' | sort
# Then for each dependency:
# bd dep add <CORE-01-id> <SETUP-01-id>
# bd dep add <API-01-id> <CORE-01-id>
# bd dep add <UI-01-id> <API-01-id>
\`\`\`

---

## SETUP-01: Add provider constant

### Priority
P0

### Type
task

### Labels
my-project, phase-0

### Description

**Context:**
All providers must be declared in a central constant before use.

**Specification:**
Add `MY_PROVIDER: 'my_provider'` to the PROVIDERS object in `src/constants.ts`.

**Files:**
- Modify: src/constants.ts

### Acceptance Criteria
- [ ] PROVIDERS.MY_PROVIDER === 'my_provider'
- [ ] Passes: pnpm typecheck

## CORE-01: Implement client

### Priority
P0

### Type
task

### Labels
my-project, phase-1

### Description

**Context:**
Need a typed client to interact with the external API.

**Specification:**
Create `src/lib/my-client.ts` with methods for list, get, create operations.
Handle rate limiting with exponential backoff.

**Files:**
- Create: src/lib/my-client.ts
- Reference: src/lib/other-client.ts

### Acceptance Criteria
- [ ] Client handles rate limits
- [ ] All methods return typed responses
- [ ] Passes: pnpm typecheck
```

## Add Dependencies

After creating beads, run this script:

\`\`\`bash
#!/bin/bash
set -e

declare -A IDS
while IFS=': ' read -r key value; do
  IDS[$key]=$value
done < <(bd list -l my-project --json | jq -r '.[] | "\(.title | split(":")[0]): \(.id)"')

# CORE-01 depends on SETUP-01
bd dep add ${IDS[CORE-01]} ${IDS[SETUP-01]}
# API-01 depends on CORE-01
bd dep add ${IDS[API-01]} ${IDS[CORE-01]}
# UI-01 depends on API-01
bd dep add ${IDS[UI-01]} ${IDS[API-01]}

bd sync
echo "Done!"
\`\`\`

## Verification Checklist

Before finalizing, verify:
- [ ] Every TDD requirement maps to ≥1 bead
- [ ] No orphan beads (all map back to TDD)
- [ ] Each bead has ONE responsibility
- [ ] No `## ` headers inside Description sections
- [ ] All dependencies listed in Deps section
- [ ] Dependency commands section is complete
- [ ] Labels include project name and phase
