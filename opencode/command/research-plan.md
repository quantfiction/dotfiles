Route the rough plan through targeted or deep research to gather verified facts.

## Inputs required
- Project slug (e.g., "my-feature")
- INTAKE.md from Stage 0 (docs/plans/<project>/INTAKE.md)

## Research modes
- `targeted`: Required sub-agents only (Codebase Analyst, API/SDK Researcher, Learnings Retriever)
- `deep`: All sub-agents including Best Practices Scout and Git History Analyzer

## Evidence rules (locked)
- Every Verified Fact MUST include `Source:` (repo path or URL)
- Every UNVERIFIED item MUST include `How to verify:`
- External API calls MUST have contract block (verified or UNVERIFIED)

## Output
Create `docs/plans/<project>/RESEARCH_DOSSIER.md` with:
- YAML frontmatter (schemaVersion, artifactType, project, createdAt, researchMode, sourceIntake)
- Verified Facts (with sources)
- Repo Integration Findings (files to create/modify, patterns, helpers)
- External APIs / Services (with contracts)
- Version & Dependency Notes
- Known Unknowns (UNVERIFIED items with verification steps)
- Decisions Required (conflicts surfaced during research)

## Convergence rules
- RESEARCH_DOSSIER.md passes schema validation
- net-new research issues in current pass <= 1
- All targeted triggers covered
- regression count is 0

## Next steps
- Track M: `/plan-polish` (lite schema)
- Track L: `/plan-polish` (full schema)

Load the `research-plan` skill for detailed implementation guidance.
