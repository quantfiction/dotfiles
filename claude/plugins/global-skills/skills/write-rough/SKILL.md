---
name: write-rough
description: Structure exploration results into a ROUGH.md that intake can consume. Use at the end of a planning conversation, not the beginning.
---

# Write Rough Plan

Structure the results of an exploration session into a `ROUGH.md` that the planning lifecycle can consume.

## When to use

Use at the **end** of a planning conversation — after you've explored the problem, discussed approaches, investigated the codebase, and reached a direction. This skill doesn't generate ideas; it captures what was already decided.

Do NOT use:
- At the start of a session (explore first, structure later)
- As a replacement for thinking (the exploration is the work; this is the packaging)
- For Track S work (just implement it)

## Role

You are structuring an exploration session's conclusions into a format that intake, research, and plan-polish can consume reliably.

## What this is NOT

This is not a design document. It's not a TDD. It's the rough sketch that feeds into the planning lifecycle:

```
exploration session → ROUGH.md → /intake → /research → /plan-polish → ...
```

The ROUGH should capture the *what* and *why* clearly, the *how* roughly, and be honest about what was verified vs. assumed. Downstream skills will refine it. Your job is to give them a clean starting point, not a finished plan.

## Required inputs

- A conversation/session where a problem was explored and a direction was chosen
- A project slug for file naming

## Output

Create `docs/plans/<project>/ROUGH.md` with the structure below.

## Structure

```markdown
# Rough Plan — <project slug>

## Problem

What's wrong / what's missing / what needs to change. Be specific about the
pain point. Include examples of failures or limitations if they came up
during exploration.

## Proposed Approach

What we're going to do about it. This can range from a paragraph to several
pages depending on how much exploration happened. Include:
- The high-level strategy
- Key design decisions already made (and why)
- Alternatives that were considered and rejected (and why)

## Scope

### In scope
- <what this plan covers>

### Out of scope
- <what this plan explicitly does NOT cover>

### Files / areas likely affected
- <list files, modules, or areas that will change>
- <include files discovered during exploration>

## Confidence Map

Tag each major claim with a confidence level. This is the most important
section for downstream skills — it tells intake what to spot-check and
research what to investigate.

| # | Claim | Confidence | Basis |
|---|-------|------------|-------|
| 1 | <factual claim about the codebase or approach> | verified | <how: grep result, file read, test run> |
| 2 | <claim about what's affected or safe> | assumed | <why you believe it, but didn't check> |
| 3 | <estimate of effort or scope> | estimated | <basis for estimate> |
| 4 | <claim about external behavior> | unverified | <what would need to be checked> |

**Confidence levels:**
- **verified** — checked during this session (grepped, read the file, ran a test)
- **assumed** — reasonable belief based on experience/context, but not checked against code
- **estimated** — rough sizing or scoping, may be off
- **unverified** — don't know, needs investigation

Every claim about "X is unaffected" or "only files A, B, C need changes"
MUST appear in this table. These are the claims intake will spot-check.

## Open Questions

Things that came up during exploration but weren't resolved. Split by urgency:

### Must resolve before implementation
- <blocking questions>

### Can defer
- <nice-to-know but not blocking>

## Context / References

Links, prior art, related issues, conversation highlights, or anything
that would help the next agent understand why this direction was chosen.
```

## Guidelines

### Be honest about confidence
The whole point of the confidence map is to prevent the downstream lifecycle from trusting unverified claims. If you explored the codebase and confirmed something, say `verified`. If you're guessing based on how things usually work, say `assumed`. Intake will route higher-ambiguity plans through more rigorous verification. That's the system working correctly — don't game it by marking assumptions as verified.

### Scope is a commitment
What's listed as "out of scope" won't be planned, researched, or implemented. If something is uncertain, put it in Open Questions, not out-of-scope.

### Capture rejected alternatives
Future sessions won't have this conversation's context. If you considered approach B and rejected it, say why. This prevents research and review from re-proposing it.

### Don't over-specify the how
The ROUGH feeds into plan-polish, which produces a detailed TDD. If you specify implementation details here, they'll either be duplicated (waste) or contradict the TDD (confusion). Describe the approach at the level of "we'll replace X with Y using Z strategy," not "in file A, change line 34 to..."

### When the exploration was deep
If the session did heavy codebase investigation — reading files, running queries, tracing consumers — capture those findings in the Confidence Map as `verified` claims with the evidence. This is gold for downstream skills; it lets intake fast-track and research skip re-investigation.

### When the exploration was shallow
If this is primarily a user request ("I want X"), that's fine. Most claims will be `assumed` or `unverified`, the confidence map will be short, and intake will score high ambiguity and route through deep research. The system handles this.

## Quality gate

Before finishing, confirm:
- [ ] Problem section explains the pain point, not just the solution
- [ ] Proposed Approach includes key decisions and rejected alternatives
- [ ] Scope has explicit in-scope and out-of-scope lists
- [ ] Confidence Map exists and has at least one entry
- [ ] Every "X is unaffected" or "only these files change" claim is in the Confidence Map
- [ ] No confidence level is `verified` without a concrete basis (grep, file read, test)
- [ ] Open Questions are split into blocking vs. deferrable
- [ ] File is saved to `docs/plans/<project>/ROUGH.md`
