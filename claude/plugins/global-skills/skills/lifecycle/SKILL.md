---
name: lifecycle
description: Run the full planning → review → implementation pipeline autonomously via the lifecycle CLI
---

# Lifecycle Orchestrator

Drive a project through the complete planning pipeline autonomously:

```
intake → research → plan-polish → review-design → write-beads → bead-review → create-beads → implement
```

## Prerequisites

- `pi` installed and configured (API keys set)
- `bd` installed (bead/issue tracker)
- `~/bin/lifecycle` on PATH (installed via `~/dotfiles/install.sh pi`)

## When to use

Use when you have:
- A rough plan at `docs/plans/<project>/ROUGH.md`
- Want to run the full planning lifecycle hands-free
- Want to skip manual skill chaining

Do NOT use:
- For Track S work (simple tasks — just implement directly)
- When you want manual control over individual phases

## CRITICAL: How to invoke

**Always run lifecycle in background mode** with `--bg`. The pipeline runs for
30-60+ minutes and WILL be killed by bash tool timeouts if run in the foreground.

```bash
# Start in background — returns immediately with monitoring instructions
lifecycle docs/plans/my-feature/ROUGH.md --bg

# Check progress (shows current phase + last 15 log lines)
lifecycle docs/plans/my-feature/ROUGH.md --status

# Read the full log
cat docs/plans/my-feature/lifecycle.log
```

### Monitoring workflow

After launching with `--bg`, poll status periodically:

```bash
lifecycle docs/plans/my-feature/ROUGH.md --status
```

The status output tells you:
- **Status**: RUNNING or STOPPED
- **Phase**: Which phase is currently executing
- **Detail**: What's happening within that phase
- **Log**: Path to the full log file

If status shows STOPPED and the phase isn't "complete", check the log for errors
and resume with `--skip-to`:

```bash
# Read the log to see what failed
cat docs/plans/my-feature/lifecycle.log

# Resume from where it stopped
lifecycle docs/plans/my-feature/ROUGH.md --bg --skip-to bead-review
```

## Quick Start

```bash
# Full pipeline (backgrounded)
lifecycle docs/plans/my-feature/ROUGH.md --bg

# Dry run to see what would happen (fast, no need for --bg)
lifecycle docs/plans/my-feature/ROUGH.md --dry-run

# Resume from a specific phase
lifecycle docs/plans/my-feature/ROUGH.md --bg --skip-to implement

# Limit parallel workers during implementation
lifecycle docs/plans/my-feature/ROUGH.md --bg --max-workers 2

# Override the model for authoring sessions
lifecycle docs/plans/my-feature/ROUGH.md --bg --model claude-opus-4-6

# Tail the log live (in your terminal, NOT through an agent)
lifecycle docs/plans/my-feature/ROUGH.md --tail
```

## What it does

### Phase 1: Author
Runs in a single pi session (RPC mode) so context carries forward:
1. `/intake` — scores complexity, determines track (S/M/L), research mode, review mode
2. `/research-plan` — gathers verified facts (if research mode ≠ none)
3. `/plan-polish` — creates `TECHNICAL_DESIGN.md`

### Phase 2: Design Review Loop
Spawns **fresh** `pi -p --no-session` for each review (unbiased reviewer):
1. `/review-design` → parses `DESIGN_REVIEW.md` verdict
2. If `REVISE_AND_RESUBMIT`: sends revision prompt to the warm author session, then re-reviews
3. Loops until `APPROVED_FOR_DECOMPOSITION` (max 5 iterations)

### Phase 3: Write Beads + Bead Review Loop
1. `/write-beads` in the author session → `BEADS.md`
2. Fresh `/bead-review` → parses `BEADS_LEDGER.md`
3. If findings: `/bead-fix`, then re-review
4. Loops until `APPROVED` (max 5 iterations)

### Phase 4: Crystallize
- `/create-beads` — imports approved beads into `bd`

### Phase 5: Implement
Launches a pi session that:
1. Reads the dependency DAG via `bd ready -l <label>`
2. Dispatches `worker` subagents in parallel waves
3. Each worker: reads bead details, implements, runs tests, closes with `bd close`
4. Repeats waves until the DAG is exhausted
5. Retries failed beads up to 3 times

## Artifacts produced

All artifacts land in `docs/plans/<project>/`:

| File | Phase | Description |
|------|-------|-------------|
| `INTAKE.md` | 1 | Complexity score, track, research/review modes |
| `RESEARCH_DOSSIER.md` | 1 | Verified facts, API contracts, unknowns |
| `TECHNICAL_DESIGN.md` | 1-2 | Implementation-grade design document |
| `DESIGN_REVIEW.md` | 2 | Review findings and verdict |
| `DESIGN_LEDGER.md` | 2 | Issue lifecycle across review passes |
| `BEADS.md` | 3 | Atomic implementation tasks with dependency graph |
| `BEADS_LEDGER.md` | 3 | Bead review findings and lifecycle |
| `lifecycle.log` | all | Full timestamped log of the run |
| `lifecycle.status` | all | Machine-readable current status (JSON) |

## Resuming after failure

If the pipeline fails mid-run, use `--skip-to` to resume:

```bash
# Design review approved, but bead review failed — resume from bead review
lifecycle docs/plans/my-feature/ROUGH.md --bg --skip-to bead-review

# Beads are in bd, just need implementation
lifecycle docs/plans/my-feature/ROUGH.md --bg --skip-to implement
```

Check which artifacts exist in `docs/plans/<project>/` to determine where you are.

## Safety valves

- Max 5 design review iterations
- Max 5 bead review iterations
- Max 3 retries per bead implementation failure
- Track S auto-exits after intake (no planning overhead for simple tasks)
