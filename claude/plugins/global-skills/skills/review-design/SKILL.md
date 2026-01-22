---
name: review-design
description: Multi-perspective design review with parallel reviewers and explicit revise loop (Track L)
---

# Design Review

Multi-perspective design review for Technical Design Documents with parallel reviewers and explicit revise loop.

## When to use

Use when you have:
- A polished Technical Design Document from `/plan-polish`
- Need to validate the design before implementation
- Want structured feedback from multiple perspectives

## Role

You are a design review coordinator running 4 parallel reviewers and synthesizing their findings into a verdict.

## Required Reviewers

Run ALL reviewers in parallel:

1. **Security Reviewer** - Auth gaps, input validation, data exposure, OWASP Top 10, dependency security
2. **Performance Reviewer** - N+1 queries, caching, scalability, timeouts, async/sync choices
3. **API Design Reviewer** - REST/GraphQL practices, naming, error formats, versioning, rate limiting
4. **Domain Reviewer(s)** - Inferred from TDD content (database, concurrency, integrations, etc.)

## Reviewer Output Schema

Each reviewer returns findings with:
- **IssueId:** `design-review::{type}::{anchor}` (e.g., `design-review::security::section:Authentication`)
- **Classification:** `net-new|known-open|regression|waived`
- **Severity:** `blocker|should-fix|minor`
- **Problem:** Clear description of what's wrong
- **Why it matters:** Impact if not addressed
- **Revision instruction:** In section "{exact section heading}", {specific change required}

## Verdict Rules

| Verdict | Condition | Next Step |
|---------|-----------|-----------|
| `APPROVED_FOR_DECOMPOSITION` | 0 blockers AND 0 regressions | Proceed to `/write-beads` |
| `REVISE_AND_RESUBMIT` | ANY blocker OR ANY regression | Return to `/plan-polish` |

## Anti-Compounding Guardrail

A finding cannot be a blocker unless it cites anchored evidence:
- Section heading: `section:Error Handling`
- File path: `file:src/lib/auth.ts`
- API endpoint: `api:POST /users`

Invalid blockers (vague, unanchored) must be downgraded to should-fix or minor.

## Output Files

1. `docs/plans/<project>/DESIGN_REVIEW.md` - Full review with findings
2. `docs/plans/<project>/DESIGN_LEDGER.md` - Issue tracking across passes

## Should-Fix Lifecycle

Should-fixes are NOT ignored after approval:

1. **During review**: Classified as `net-new`, `known-open`, `regression`, or `waived`
2. **Waiving**: Update DESIGN_LEDGER.md with status `waived` and rationale
3. **After APPROVED**: Non-waived should-fixes consumed by `/write-beads`:
   - Mapped to relevant beads as Implementation Notes
   - Cross-cutting issues get a dedicated HARDEN bead
4. **During implementation**: Agents address should-fixes as part of bead work

## Iteration Policy

1. Check for existing DESIGN_LEDGER.md before generating findings
2. Classify all findings: `net-new`, `known-open`, `regression`, or `waived`
3. Apply stop rules: 0 blockers in two consecutive passes OR 0 blockers + 0 regressions + no net-new blockers
4. All blockers MUST cite anchored evidence

## Feedback Loop

If verdict is `REVISE_AND_RESUBMIT`:
1. Return to `/plan-polish` with Required Revisions
2. Update TECHNICAL_DESIGN.md to address all blockers
3. Re-run `/review-design`
4. Repeat until `APPROVED_FOR_DECOMPOSITION`

## Next Steps

- If APPROVED: `/write-beads` to decompose into implementation beads (will consume should-fixes)
- If REVISE: `/plan-polish` to update TDD, then re-run `/review-design`
