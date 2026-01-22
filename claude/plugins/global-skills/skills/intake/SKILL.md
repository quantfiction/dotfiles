---
name: intake
description: Route work deterministically via complexity scoring to the appropriate workflow track (S/M/L).
---

# Intake

Route work deterministically and record routing decisions via complexity scoring.

## When to use

Use at the start of any non-trivial work when you have:
- A rough plan or feature request
- Need to determine the appropriate workflow track
- Want to assess whether research is needed

## Role

You are a workflow router that objectively scores work complexity and routes to the appropriate track.

## Required Inputs

- Project slug (e.g., "my-feature")
- Rough plan from Stage 1 (`docs/plans/<project>/ROUGH.md`)

## Scoring Rubric (Locked)

Score each dimension independently:

### 1. Scope Breadth (0-2 points)
| Score | Criteria |
|-------|----------|
| 0 | Single file or function change |
| 1 | Multiple files in one module/directory |
| 2 | Cross-module or cross-service changes |

### 2. Data/Migrations (0-3 points)
| Score | Criteria |
|-------|----------|
| 0 | No data changes |
| 1 | Schema changes, backwards compatible |
| 2 | Schema changes requiring migration |
| 3 | Data migration with transformation logic |

### 3. Workflow Complexity (0-2 points)
| Score | Criteria |
|-------|----------|
| 0 | Synchronous, single-path logic |
| 1 | Async operations or multiple paths |
| 2 | Distributed transactions, sagas, or complex state machines |

### 4. User-Facing Risk (0-2 points)
| Score | Criteria |
|-------|----------|
| 0 | Internal tooling or non-user-facing |
| 1 | User-facing but low-traffic or reversible |
| 2 | High-traffic, payment-related, or hard to reverse |

### 5. Ambiguity (0-2 points)
| Score | Criteria |
|-------|----------|
| 0 | Requirements are clear and complete |
| 1 | Some details need clarification |
| 2 | Significant unknowns or research required |

## Track Mapping

| Total Score | Track | Research Mode | Next Step |
|-------------|-------|---------------|-----------|
| 0-1 | S (Small) | none | Direct to implementation |
| 2-4 | M (Medium) | targeted | `/research-plan` with targeted mode |
| 5+ | L (Large) | deep | `/research-plan` with deep mode |

## Output Schema

Create `docs/plans/<project>/INTAKE.md`:

```yaml
---
schemaVersion: "1.0"
artifactType: INTAKE
project: <project-slug>
createdAt: <ISO8601>
sourceRough: docs/plans/<project>/ROUGH.md
---
```

### Required Sections

1. **Summary** - One-line description of the work
2. **Scoring Breakdown** - Each dimension with score and justification
3. **Total Score** - Sum with track assignment
4. **Research Mode** - none/targeted/deep with rationale
5. **Routing Decision** - Clear next step with reasoning

## Routing Rules

- Track S: Skip research, proceed directly to implementation
- Track M: Run `/research-plan` in targeted mode
- Track L: Run `/research-plan` in deep mode

## Next Steps

| Track | Next Skill |
|-------|------------|
| S | Direct implementation (or `/write-beads` for tracking) |
| M | `/research-plan --mode=targeted` |
| L | `/research-plan --mode=deep` |
