---
name: create-beads
description: Import a BEADS.md file into bd and set up dependencies. Use after /write-beads and /bead-review.
---

# Create Beads

Import a reviewed BEADS.md file into the bd issue tracker and configure all dependencies.

## When to use

Use after:
1. `/write-beads` has created the BEADS.md file
2. `/bead-review` has verified the beads are correct

## Workflow

### Step 0: Run schema validation

Before importing, run the plan validator to ensure the BEADS.md file conforms to schema requirements:

```bash
pnpm validate:plans -- --path docs/plans/<project>
```

**This is a hard stop.** If validation fails, do NOT proceed to `bd create`. Fix the schema errors first, then re-run validation.

**Expected output (success):**
```
✓ All plans validated successfully
```

**On failure:** The validator will report specific schema errors. Fix them in the BEADS.md file before continuing.

### Step 1: Validate the BEADS.md file

Confirm the file exists and has the required sections:
- Bead definitions (## ID: Title format)
- Dependency script (bash script with `bd dep add` commands; do not use `bd update --blocked-by`)

```bash
# Check file exists
ls docs/plans/<project>/BEADS.md

# Count beads (## headers that look like bead IDs)
grep -c "^## [A-Z]" docs/plans/<project>/BEADS.md
```

### Step 2: Create beads in bd

```bash
bd create -f docs/plans/<project>/BEADS.md
```

This creates all beads with their priority, type, labels, description, and acceptance criteria.

**Expected output:**
```
✓ Created N issues from docs/plans/<project>/BEADS.md:
  mindhive-xxxx: SETUP-01: Title [P0, task]
  mindhive-yyyy: SETUP-02: Title [P0, task]
  ...
```

### Step 3: Add dependencies

Extract and run the dependency script from BEADS.md:

```bash
# The script is in the "Add Dependencies" section of BEADS.md
# Extract it or run it directly

#!/bin/bash
set -e

# Get bead ID mapping
declare -A IDS
while IFS=': ' read -r key value; do
  IDS[$key]=$value
done < <(bd list -l <project-label> --json | jq -r '.[] | "\(.title | split(":")[0]): \(.id)"')

# Add each dependency (copy from BEADS.md)
bd dep add ${IDS[CHILD-ID]} ${IDS[PARENT-ID]}
# ... continue for all dependencies

bd sync
```

### Step 4: Verify

```bash
# Check all beads were created
bd list -l <project-label> --json | jq 'length'

# Check ready beads (no blockers)
bd ready -l <project-label>

# Verify dependency count
bd list -l <project-label> --json | jq '[.[].dependencies // [] | length] | add'
```

### Step 5: Report

Summarize:
- Total beads created
- Beads by priority (P0/P1/P2)
- Ready beads (no blocking dependencies)
- Any errors encountered

## Error Handling

### "No issues found in markdown file"
The BEADS.md uses wrong format. Beads must use `## ID: Title` format (H2), not `### ` or YAML blocks.

### "dependency target X not found"
Dependencies cannot reference symbolic IDs during creation. The dependency script must run AFTER beads are created.

### Duplicate beads
If beads already exist, `bd create -f` will create duplicates. Check first:
```bash
bd list -l <project-label> --json | jq 'length'
```

## Example Session

```
User: /create-beads docs/plans/slack-integration/BEADS.md

Agent: I'll import the beads and set up dependencies.

Step 0: Running schema validation...
$ pnpm validate:plans -- --path docs/plans/slack-integration
✓ All plans validated successfully

Step 1: Validating BEADS.md...
Found 19 bead definitions.
Found dependency script with 24 dependencies.

Step 2: Creating beads...
$ bd create -f docs/plans/slack-integration/BEADS.md
✓ Created 19 issues

Step 3: Adding dependencies...
$ # Running dependency script...
✓ Added 24 dependencies

Step 4: Verification
- Total beads: 19
- P0: 7, P1: 11, P2: 1
- Ready to implement: 5 (SETUP-01, SETUP-02, SETUP-03, CORE-02, CORE-03)

Step 5: Syncing...
$ bd sync
✓ Sync complete

Done! 19 beads created with 24 dependencies.
Ready beads: SETUP-01, SETUP-02, SETUP-03, CORE-02, CORE-03
```
