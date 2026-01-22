# Design Review
Multi-perspective design review with parallel reviewers and explicit revise loop (Track L).

## What this does
- Runs 4 parallel reviewers: Security, Performance, API Design, Domain (inferred)
- Each reviewer produces findings with severity (blocker/should-fix/minor)
- Synthesizes findings into verdict: APPROVED_FOR_DECOMPOSITION or REVISE_AND_RESUBMIT
- Required Revisions reference specific TECHNICAL_DESIGN.md section headings
- Integrates with iteration policy for convergence and ledger tracking

## Usage
Provide the polished Technical Design Document from `/plan-polish`.

Output goes to `docs/plans/<project>/DESIGN_REVIEW.md` and updates `docs/plans/<project>/DESIGN_LEDGER.md`.

## Required reviewers
1. **Security Reviewer** - Auth, validation, data exposure, OWASP Top 10
2. **Performance Reviewer** - N+1 queries, caching, scalability, timeouts
3. **API Design Reviewer** - REST/GraphQL practices, naming, error formats
4. **Domain Reviewer(s)** - Inferred from TDD content (database, concurrency, etc.)

## Verdict rules
- ANY blocker exists → `REVISE_AND_RESUBMIT`
- ANY regression exists → `REVISE_AND_RESUBMIT`
- Otherwise → `APPROVED_FOR_DECOMPOSITION`

## Finding classification
All findings must be classified as: `net-new`, `known-open`, `regression`, or `waived`.

## Iteration policy
- Consumes existing DESIGN_LEDGER.md before generating findings
- Applies stop rules: 0 blockers + 0 regressions in two consecutive passes
- All blockers must cite anchored evidence (section heading, file path, API endpoint)

## Should-Fix Handling

Should-fixes are NOT ignored after approval. They follow this lifecycle:

1. **During review**: Classified as `net-new`, `known-open`, `regression`, or `waived`
2. **Waiving**: Issues can be marked `waived` with rationale in DESIGN_LEDGER.md
3. **After APPROVED**: Non-waived should-fixes are consumed by `/write-beads`:
   - Mapped to relevant beads as Implementation Notes
   - Cross-cutting issues get a dedicated HARDEN bead
4. **During implementation**: Agents address should-fixes as part of bead work

**To waive a should-fix**: Update DESIGN_LEDGER.md with status `waived` and rationale.

## Feedback loop
If verdict is `REVISE_AND_RESUBMIT`:
1. Return to `/plan-polish` with Required Revisions
2. Update TECHNICAL_DESIGN.md
3. Re-run `/review-design` until `APPROVED_FOR_DECOMPOSITION`

## Next steps
- If APPROVED: Run `/write-beads` to decompose into implementation beads (will consume should-fixes)
- If REVISE: Update TDD via `/plan-polish`, then re-run `/review-design`
