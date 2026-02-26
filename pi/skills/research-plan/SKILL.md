---
name: research-plan
description: Route the rough plan through targeted or deep research to gather verified facts.
---

# Research Plan (pi subagent-enabled)

This skill extends the base `research-plan` skill with real subagent dispatch.

## Base Skill

First, read and follow the base skill at `~/dotfiles/claude/plugins/global-skills/skills/research-plan/SKILL.md` for the full workflow, output schema, evidence rules, and convergence rules.

**Everything in the base skill applies.** This overlay ONLY changes how research sub-agents are dispatched.

## Subagent Dispatch

Instead of simulating research perspectives internally, dispatch them as real parallel subagents using the `subagent` tool.

### Targeted Research (Track M — 3 agents)

```
subagent parallel:
  - codebase-analyst: "Analyze the codebase for patterns, similar implementations, helpers, and conventions relevant to: <brief description from INTAKE.md>. Focus on: <research triggers from INTAKE.md>."
  - api-researcher: "Research external APIs and SDKs needed for: <brief description from INTAKE.md>. Verify contracts, auth flows, rate limits. Focus on: <research triggers from INTAKE.md>."
  - learnings-retriever: "Search the project's history for past decisions, ADRs, postmortems, and known pitfalls relevant to: <brief description from INTAKE.md>. Focus on: <research triggers from INTAKE.md>."
```

### Deep Research (Track L — 5 agents)

```
subagent parallel:
  - codebase-analyst: "Analyze the codebase for patterns, similar implementations, helpers, and conventions relevant to: <brief description from INTAKE.md>. Focus on: <research triggers from INTAKE.md>."
  - api-researcher: "Research external APIs and SDKs needed for: <brief description from INTAKE.md>. Verify contracts, auth flows, rate limits. Focus on: <research triggers from INTAKE.md>."
  - learnings-retriever: "Search the project's history for past decisions, ADRs, postmortems, and known pitfalls relevant to: <brief description from INTAKE.md>. Focus on: <research triggers from INTAKE.md>."
  - best-practices-scout: "Research industry standards, security guidelines, and proven patterns for: <brief description from INTAKE.md>. Focus on: <research triggers from INTAKE.md>."
  - git-history-analyzer: "Analyze git history for code evolution context, past refactoring, and change patterns relevant to: <brief description from INTAKE.md>. Focus on: <research triggers from INTAKE.md>."
```

## Your Role as Compiler

After the parallel subagents return, YOU (the main agent) compile the `RESEARCH_DOSSIER.md`:

1. **Collect** all outputs from the research agents
2. **Organize** into the dossier schema sections (Verified Facts, Repo Integration, External APIs, etc.)
3. **Cross-reference** — if the codebase-analyst and api-researcher found conflicting info, flag it
4. **Validate evidence rules** — every fact has a `Source:`, every unverified item has `How to verify:`
5. **Identify gaps** — if research triggers from INTAKE.md aren't covered, note them as Known Unknowns
6. **Produce** `docs/plans/<project>/RESEARCH_DOSSIER.md` per the base skill schema

## Why Subagents

- **Scope isolation**: The codebase analyst digs through code while the API researcher fetches docs — no context pollution
- **Web access**: api-researcher and best-practices-scout have web tools; codebase-analyst and git-history-analyzer don't need them
- **True parallelism**: All agents research simultaneously
- **Cost efficiency**: Research agents run on Sonnet 4.6, compilation on your model (Opus)
