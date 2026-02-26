---
name: research-plan
description: Route the rough plan through targeted or deep research to gather verified facts.
---

# Research Plan

Route the rough plan through targeted or deep research to gather verified facts.

## When to use

Use after `/intake` determines that research is needed (Track M or L) and you have:
- A scored INTAKE.md with research mode recommendation
- Need to gather verified facts before detailed planning

## Role

You are a research coordinator spawning specialized sub-agents to gather evidence for the implementation plan.

## Required Inputs

- Project slug (e.g., "my-feature")
- INTAKE.md from Stage 0 (`docs/plans/<project>/INTAKE.md`)

## Research Modes

| Mode | When | Sub-agents |
|------|------|------------|
| `targeted` | Track M (2-4 points) | Codebase Analyst, API/SDK Researcher, Learnings Retriever |
| `deep` | Track L (5+ points) | All targeted + Best Practices Scout, Git History Analyzer |

## Sub-agent Responsibilities

1. **Codebase Analyst** - Existing patterns, similar implementations, helper functions, test patterns. **MUST also verify the ROUGH plan's assumptions**: trace all consumers of interfaces being changed/deleted, verify "X is unaffected" claims, and report any consumers the plan doesn't account for.
2. **API/SDK Researcher** - External API contracts, SDK documentation, authentication flows
3. **Learnings Retriever** - Past decisions, ADRs, postmortems, relevant issues
4. **Best Practices Scout** (deep only) - Industry standards, security guidelines, performance patterns
5. **Git History Analyzer** (deep only) - Why code evolved, past attempts, refactoring context

## Evidence Rules (Locked)

These rules are non-negotiable:

| Rule | Requirement |
|------|-------------|
| Verified Facts | MUST include `Source:` with repo path or URL |
| UNVERIFIED Items | MUST include `How to verify:` with concrete steps |
| External API Calls | MUST have contract block (verified OR marked UNVERIFIED) |

## Output Schema

Create `docs/plans/<project>/RESEARCH_DOSSIER.md` with:

```yaml
---
schemaVersion: "1.0"
artifactType: RESEARCH_DOSSIER
project: <project-slug>
createdAt: <ISO8601>
researchMode: targeted|deep
sourceIntake: docs/plans/<project>/INTAKE.md
---
```

### Required Sections

1. **ROUGH Assumption Audit** - For each assumption from INTAKE.md's verification table: grep results, consumer lists, and verdict (confirmed/contradicted/nuanced). If the ROUGH claims "X is unaffected," list every file that consumes X. **This section is mandatory and must be completed before other sections.** If INTAKE.md has no assumption verification table, the codebase analyst must identify and verify the ROUGH's 3-5 most load-bearing assumptions independently.
2. **Verified Facts** - Facts with sources, grouped by category
3. **Repo Integration Findings** - Files to create/modify, patterns to follow, available helpers. Must incorporate findings from the assumption audit — if the audit found consumers the ROUGH missed, they must appear here.
4. **External APIs / Services** - Contracts (verified or UNVERIFIED), auth requirements
5. **Version & Dependency Notes** - Compatibility concerns, required upgrades
6. **Known Unknowns** - UNVERIFIED items with specific verification steps
7. **Decisions Required** - Conflicts or ambiguities surfaced during research

## Convergence Rules

Research is complete when ALL conditions are met:
- RESEARCH_DOSSIER.md passes schema validation
- Net-new research issues in current pass <= 1
- All targeted triggers from INTAKE.md are covered
- Regression count is 0

## Next Steps

| Track | Next Skill |
|-------|------------|
| Track M | `/plan-polish` (lite schema - skip detailed risk analysis) |
| Track L | `/plan-polish` (full schema - complete TDD) |
