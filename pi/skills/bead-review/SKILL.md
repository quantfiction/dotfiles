---
name: bead-review
description: QA/adversarial audit of bead decomposition for autonomous agent execution
---

# Bead Review Workflow (pi subagent-enabled)

This skill extends the base `bead-review` skill with real subagent dispatch.

## Base Skill

First, read and follow the base skill at `~/dotfiles/claude/plugins/global-skills/skills/bead-review/SKILL.md` for the full workflow, output format, verdict rules, iteration policy, convergence rules, and IssueId format.

**Everything in the base skill applies.** This overlay ONLY changes how checkers are dispatched.

## Subagent Dispatch

Instead of simulating 5 checker perspectives internally, dispatch them as real parallel subagents using the `subagent` tool.

### Dispatch All 5 Checkers

```
subagent parallel:
  - coverage-checker: "Review BEADS.md at docs/plans/<project>/BEADS.md against the TDD at docs/plans/<project>/TECHNICAL_DESIGN.md. Read the ledger at docs/plans/<project>/BEADS_LEDGER.md if it exists. Output findings in the schema from your system prompt."
  - atomicity-checker: "Review BEADS.md at docs/plans/<project>/BEADS.md for sizing and single-responsibility. Read the ledger at docs/plans/<project>/BEADS_LEDGER.md if it exists. Output findings in the schema from your system prompt."
  - dependency-validator: "Review BEADS.md at docs/plans/<project>/BEADS.md for dependency graph integrity. Read the ledger at docs/plans/<project>/BEADS_LEDGER.md if it exists. Output findings in the schema from your system prompt."
  - context-auditor: "Review BEADS.md at docs/plans/<project>/BEADS.md for self-sufficiency. Each bead must be implementable by an autonomous agent without reading other beads. Read the ledger at docs/plans/<project>/BEADS_LEDGER.md if it exists. Output findings in the schema from your system prompt."
  - metadata-checker: "Review BEADS.md at docs/plans/<project>/BEADS.md for metadata completeness (Parallelism, Confidence, labels, priority, type). Read the ledger at docs/plans/<project>/BEADS_LEDGER.md if it exists. Output findings in the schema from your system prompt."
```

## Your Role as Synthesizer

After the parallel subagents return, YOU (the main agent) act as the Review Synthesizer:

1. **Merge** all findings from the 5 checker outputs
2. **Deduplicate** — a coverage gap and a missing dependency may be the same root cause
3. **Consume ledger** — read `BEADS_LEDGER.md` if it exists
4. **Classify** each finding: `net-new`, `known-open`, `regression`, or `waived`
5. **Apply anti-compounding guardrail** — a blocker MUST cite anchored evidence
6. **Produce verdict** — `APPROVED` or findings with Required Fixes
7. **Update** `BEADS_LEDGER.md` per the base skill format
8. **Include revised beads** for any bead you changed (full `## ID: Title` section)

## Why Subagents

- **Accuracy**: BEADS.md files are thousands of lines — a single agent checking 5 dimensions loses accuracy. Dedicated checkers stay focused.
- **Fresh context**: Each checker starts with a clean context window
- **True parallelism**: All 5 checkers run simultaneously
- **Cost efficiency**: Checkers run on Sonnet 4.6, synthesis on your model (Opus)
