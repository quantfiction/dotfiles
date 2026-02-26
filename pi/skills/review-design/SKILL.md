---
name: review-design
description: Multi-perspective design review with parallel reviewers and explicit revise loop (Track L full, Track M lite)
---

# Design Review Workflow (pi subagent-enabled)

This skill extends the base `review-design` skill with real subagent dispatch.

## Base Skill

First, read and follow the base skill at `~/dotfiles/claude/plugins/global-skills/skills/review-design/SKILL.md` for the full workflow, output format, verdict rules, iteration policy, and convergence rules.

**Everything in the base skill applies.** This overlay ONLY changes how reviewers are dispatched.

## Subagent Dispatch

Instead of simulating reviewer perspectives internally, dispatch them as real parallel subagents using the `subagent` tool.

### Full Review (Track L — 5 reviewers)

Use the subagent tool in parallel mode with all 5 reviewers. Each reviewer receives the same task — the path to the TDD:

```
subagent parallel:
  - security-reviewer: "Review the TDD at docs/plans/<project>/TECHNICAL_DESIGN.md. Also read the existing ledger at docs/plans/<project>/DESIGN_LEDGER.md if it exists. Output findings in the schema from your system prompt."
  - api-reviewer: "Review the TDD at docs/plans/<project>/TECHNICAL_DESIGN.md. Also read the existing ledger at docs/plans/<project>/DESIGN_LEDGER.md if it exists. Output findings in the schema from your system prompt."
  - performance-reviewer: "Review the TDD at docs/plans/<project>/TECHNICAL_DESIGN.md. Also read the existing ledger at docs/plans/<project>/DESIGN_LEDGER.md if it exists. Output findings in the schema from your system prompt."
  - impact-reviewer: "Review the TDD at docs/plans/<project>/TECHNICAL_DESIGN.md. Also read the RESEARCH_DOSSIER.md if it exists. For every interface, model, or contract that is changed, replaced, or deleted in the TDD: grep the codebase for ALL consumers of that interface. Report as a BLOCKER any consumer that is not accounted for in the TDD's migration plan. Report as should-fix any consumer where the TDD's proposed adaptation looks incomplete or incorrect. Output findings in the standard review schema."
  - domain-reviewer: "Review the TDD at docs/plans/<project>/TECHNICAL_DESIGN.md. Also read the existing ledger at docs/plans/<project>/DESIGN_LEDGER.md if it exists. Output findings in the schema from your system prompt."
```

### Lite Review (Track M — 3 reviewers)

```
subagent parallel:
  - security-reviewer: "Review the TDD at docs/plans/<project>/TECHNICAL_DESIGN.md. Also read the existing ledger at docs/plans/<project>/DESIGN_LEDGER.md if it exists. Output findings in the schema from your system prompt."
  - api-reviewer: "Review the TDD at docs/plans/<project>/TECHNICAL_DESIGN.md. Also read the existing ledger at docs/plans/<project>/DESIGN_LEDGER.md if it exists. Output findings in the schema from your system prompt."
  - impact-reviewer: "Review the TDD at docs/plans/<project>/TECHNICAL_DESIGN.md. Also read the RESEARCH_DOSSIER.md if it exists. For every interface, model, or contract that is changed, replaced, or deleted in the TDD: grep the codebase for ALL consumers of that interface. Report as a BLOCKER any consumer that is not accounted for in the TDD's migration plan. Report as should-fix any consumer where the TDD's proposed adaptation looks incomplete or incorrect. Output findings in the standard review schema."
```

## Your Role as Synthesizer

After the parallel subagents return, YOU (the main agent) act as the Review Synthesizer:

1. **Collect** all findings from the subagent outputs
2. **Deduplicate** findings that overlap across reviewers
3. **Consume ledger** — read `DESIGN_LEDGER.md` if it exists, classify findings
4. **Apply verdict rules** from the base skill (any blocker → REVISE_AND_RESUBMIT)
5. **Apply anti-compounding guardrail** — downgrade unanchored blockers
6. **Produce** `DESIGN_REVIEW.md` and update `DESIGN_LEDGER.md` per the base skill format

## Why Subagents

- **Fresh context**: Each reviewer starts clean — no attention bleed between perspectives
- **True parallelism**: All reviewers run simultaneously
- **Cost efficiency**: Reviewers run on Sonnet 4.6, synthesis on your model (Opus)
- **Better role fidelity**: A model that is ONLY the Security Reviewer catches things a multi-role simulation misses
