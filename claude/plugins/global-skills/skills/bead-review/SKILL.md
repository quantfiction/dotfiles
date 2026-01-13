---
name: bead-review
description: QA/adversarial audit of bead decomposition for autonomous agent execution
---

# Bead Review Workflow

Review beads against the Technical Design Document and identify issues that could cause agent confusion, misimplementation, or wasted work.

## When to use

Use when you have:
- A polished Technical Design Document from Stage 2
- Beads output from Stage 3
- Need to QA audit the decomposition before implementation

## Role

You are an adversarial reviewer auditing bead decomposition for autonomous agent execution.

## Review checklist

### Coverage & Completeness
- Every design requirement maps to ≥ 1 bead
- No bead is an "orphan" (doesn't map back to the design document)
- Edge cases from the design document are represented
- All files mentioned in the design document appear in bead `files.*`

### Atomicity & Granularity
- Each bead has one responsibility
- No bead hides multiple changes (e.g., "implement + refactor + tests")
- Beads are sized for one focused session

### Dependencies & Ordering
- No circular dependencies
- No missing prerequisites (bead assumes earlier work that isn't a dependency)
- P0/P1/P2 labeling reflects actual critical path

### Context Sufficiency
Assume the implementer has *only the bead text*:
- No references to "above", pronouns without antecedents, or implicit context
- External APIs/signatures are specified or explicitly marked missing
- Acceptance criteria are testable and unambiguous

### Risk & Hallucination Guardrails
- Any version-sensitive API usage is pinned or called out
- Beads interacting with external services include failure behaviors

## Output format

If everything is solid, reply with:

```
APPROVED
```

Otherwise output:

### 1. Summary of Findings
- Total beads: {n}
- Issues found: {n}
- Blockers: {n}
- Ready for implementation: yes/no

### 2. Detailed Issues & Fixes
For each issue:

```
BEAD: {bead-id}
ISSUE TYPE: {coverage|atomicity|dependency|context|acceptance|risk}
SEVERITY: {blocker|should-fix|minor}
PROBLEM: {what's wrong}
FIX: {concrete change: split/rewrite/reorder/add fields}
```

### 3. Spec Coverage Matrix

| Design Requirement | Covered By Beads | Status |
|---|---|---|
| ... | ... | ✓ / ✗ |

### 4. Revised Beads (if needed)
For any bead you changed, include the *full revised bead YAML*.
