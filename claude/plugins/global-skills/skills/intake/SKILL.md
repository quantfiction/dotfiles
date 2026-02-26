---
name: intake
description: Route work deterministically and record routing decisions via complexity scoring
---

# Intake Workflow

Route incoming work to the appropriate track (S/M/L) based on complexity scoring and determine whether research is required before implementation.

## When to use

Use when you have:
- A rough plan (`docs/plans/<project>/ROUGH.md`) that needs complexity assessment
- Need to determine the appropriate workflow track (S/M/L)
- Want to record routing decisions before starting implementation

## Role

You are a Software Intake Analyst tasked with assessing work complexity and routing it deterministically.

## Required inputs

- **Rough plan** from Stage 1 (`docs/plans/<project>/ROUGH.md`)
- **Project slug** for output file naming

## Critical constraints

- **Do NOT start implementation** - intake is purely assessment
- **Do NOT trust the ROUGH plan's claims** - it is an unverified draft; spot-check before scoring
- Apply the scoring rubric objectively; do not inflate or deflate scores
- If overriding computed track, you MUST record the reason in Decisions Required
- For Track M, you MUST check all research triggers and review triggers and record which fired

## Assumption verification (required before scoring)

The ROUGH plan is an unverified draft. Before scoring, you MUST:

1. **List the plan's key assumptions** — every claim about what is/isn't
   affected, what can safely change, what downstream consumers exist, what
   interfaces are preserved. Extract 3-5 of the most load-bearing
   assumptions from the ROUGH.

2. **Spot-check assumptions against the codebase** — use grep/find to verify
   at least 3 assumptions. For "X is unaffected" claims, grep for consumers
   of the changed interfaces. For "only files A, B, C need changes" claims,
   search for imports/references to the things being modified. Record what
   you found, including consumer counts.

3. **Record results in the output** — each assumption gets a status:
   `verified`, `contradicted`, or `unchecked`. Contradicted assumptions
   MUST increase the Ambiguity score. Unchecked assumptions with high
   potential impact MUST be flagged as research triggers.

If the plan proposes deleting or replacing an interface/model/contract,
you MUST grep for all consumers of that interface and record the count.
A plan that claims "downstream is unaffected" while 10+ files import the
thing being deleted has contradicted assumptions, not zero ambiguity.

## Scoring rubric (locked)

Compute base track score by summing:

| Category | Points | Criteria |
|----------|--------|----------|
| Scope breadth | +2 | >= 3 packages/services |
| | +1 | 2 packages/services |
| | +0 | 1 or fewer |
| Data/migrations | +3 | Schema changes or backfill required |
| | +1 | Query/index only |
| | +0 | No data layer changes |
| Workflow complexity | +2 | Concurrency/orchestration sensitive |
| | +1 | Background jobs/retries |
| | +0 | Synchronous/simple |
| User-facing risk | +1 | Auth/authz/secrets involved |
| | +1 | Production-critical external integration |
| Ambiguity | +1 | Success criteria unclear |
| | +1 | Repo integration points unknown |
| | +1 | Assumption spot-checks contradicted ROUGH claims |
| Change surface | +2 | Replaces/deletes interfaces consumed by 10+ files |
| | +1 | Replaces/deletes interfaces consumed by 3-9 files |
| | +0 | New code only, or interfaces consumed by ≤2 files |

**Score to Track mapping:**
- 0-1 points: Track S (Small)
- 2-4 points: Track M (Medium)
- 5+ points: Track L (Large)

## Research mode determination

| Track | Research Mode |
|-------|---------------|
| S | none |
| L | deep |
| M | targeted IFF any trigger fires (see below) |

**Research triggers (for Track M only):**
1. External API/service mentioned and call signatures not already pinned
2. Suspected files/areas cannot be named
3. Related historical failures (via cass/cm) exist in same subsystem
4. Decisions required that change interface/data/external behavior
5. Assumption spot-checks found contradictions or left high-impact claims unchecked
6. Plan deletes/replaces code and claims downstream consumers are unaffected (must verify all consumers)

## Review mode determination (Track M only)

Regardless of track score, if ANY of these conditions are true, `reviewMode` is set to `lite` and a design review is required before `/write-beads`:

1. Auth/authz/secrets involved (any user-scoped data access)
2. Multiple data-mutating API endpoints
3. External API integration with untested contracts
4. Database schema changes (migrations)
5. Plan replaces/deletes interfaces consumed by 3+ files (change surface ≥ 1)

If none fire, `reviewMode=none` and Track M proceeds directly to `/write-beads` after plan-polish.

Track S always has `reviewMode=none`. Track L always has `reviewMode=full`.

## Output

Create `docs/plans/<project>/INTAKE.md` with the following structure:

```yaml
---
schemaVersion: 1
artifactType: intake
project: "<project-slug>"
createdAt: "YYYY-MM-DD"
track: S|M|L
researchMode: none|targeted|deep
reviewMode: none|lite|full
sourcePlan: "docs/plans/<project-slug>/ROUGH.md"
---
```

## Output template

```markdown
# Intake — <project-slug>

## Complexity Rating
<S|M|L>

## Routing Decision
- Track: <S|M|L>
- Research Mode: <none|targeted|deep>
- Review Mode: <none|lite|full>
- Next Commands:
  - <commands based on routing>

## Assumption Verification
(List 3-5 key assumptions from the ROUGH. Record spot-check results.)

| # | Assumption | Spot-check method | Result | Status |
|---|-----------|-------------------|--------|--------|
| 1 | <claim from ROUGH> | <grep/find command or inspection> | <what was found> | verified/contradicted/unchecked |
| 2 | ... | ... | ... | ... |
| 3 | ... | ... | ... | ... |

Consumer counts for deleted/replaced interfaces:
- <InterfaceName>: <N> files import/reference it (list key consumers)

## Scoring Breakdown
- Scope breadth: <0|1|2> points — <justification>
- Data / migrations: <0|1|3> points — <justification>
- Workflow complexity: <0|1|2> points — <justification>
- User-facing risk: <0|1|2> points — <justification>
- Ambiguity: <0|1|2|3> points — <justification, cite spot-check results>
- Change surface: <0|1|2> points — <justification, cite consumer counts>
- Total: <number>

## Research Triggers
(Check all that fired. If researchMode=none, write "Not applicable - Track S".)
- [ ] External API/service mentioned and call signatures not already pinned
- [ ] Suspected files/areas cannot be named
- [ ] Related historical failures (via cass/cm) exist in same subsystem
- [ ] Decisions required that change interface/data/external behavior
- [ ] Assumption spot-checks found contradictions or left high-impact claims unchecked
- [ ] Plan deletes/replaces code and claims downstream consumers are unaffected

## Review Triggers
(Check all that fired. Track S: "Not applicable". Track L: always full review.)
- [ ] Auth/authz/secrets involved
- [ ] Multiple data-mutating API endpoints
- [ ] External API integration with untested contracts
- [ ] Database schema changes
- [ ] Plan replaces/deletes interfaces consumed by 3+ files

## Scope Signals
- In-scope:
- Out-of-scope:
- Suspected files/areas (required if researchMode=none):

## Risk Flags
- <list any identified risks, or "None">

## Related Work
- bd: <beads references>
- cass: <historical context>
- cm: <context manager references>

## Decisions Required
- <list decisions that need human input, or "None">
```

## Next commands by routing

| Routing | Next Commands |
|---------|---------------|
| Track S | `/write-beads` (direct to implementation) |
| Track M, researchMode=none, reviewMode=none | `/plan-polish`, then `/write-beads` |
| Track M, researchMode=none, reviewMode=lite | `/plan-polish`, then `/review-design --lite`, then `/write-beads` |
| Track M, researchMode=targeted, reviewMode=none | `/research-plan`, then `/plan-polish`, then `/write-beads` |
| Track M, researchMode=targeted, reviewMode=lite | `/research-plan`, then `/plan-polish`, then `/review-design --lite`, then `/write-beads` |
| Track L | `/research-plan` (deep), then `/plan-polish`, then `/review-design`, then `/write-beads` |

## Quality gate

Before finishing, confirm:
- Assumption verification table has at least 3 entries with spot-check results
- No assumption is marked "contradicted" while Ambiguity scores 0
- Consumer counts are recorded for any deleted/replaced interfaces
- Scoring breakdown adds up correctly to Total
- Track matches Score-to-Track mapping (or override is documented)
- For Track M: all research triggers checked and researchMode matches
- For Track M: all review triggers checked and reviewMode matches
- All frontmatter fields are populated (including reviewMode)
- Next Commands match the routing decision

## Common failure modes

Avoid these errors:
- **Trusting the ROUGH at face value** — the ROUGH is an unverified draft; its claims about scope, impact, and safety MUST be spot-checked before scoring
- **Scoring Ambiguity: 0 without verification** — if you didn't grep the codebase, you don't know whether integration points are "known"; unverified ≠ unambiguous
- **Missing consumer counts for deletions** — any plan that deletes/replaces an interface must have consumers counted; "downstream is unaffected" is a claim, not a fact
- Overriding computed track without recording in Decisions Required
- Omitting research triggers check for M track
- Missing YAML frontmatter fields
- Not recording which research triggers fired when researchMode=targeted
- Listing next commands that don't match the routing
