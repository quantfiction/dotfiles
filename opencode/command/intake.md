# Intake
Route work deterministically and record routing decisions via complexity scoring.

## What this does
- Assesses complexity of a rough plan using a locked scoring rubric
- Determines the appropriate workflow track (S/M/L)
- Identifies whether research is required before implementation
- Produces a routing decision document with scoring breakdown

## Usage
Provide the project slug and rough plan location. The agent will:
1. Score the work against 5 complexity dimensions
2. Map score to track (S/M/L)
3. Determine research mode (none/targeted/deep)
4. Generate `docs/plans/<project>/INTAKE.md` with routing decision

## Required inputs
- Project slug (e.g., "my-feature")
- Rough plan from Stage 1 (`docs/plans/<project>/ROUGH.md`)

## Scoring dimensions
- Scope breadth (0-2 points)
- Data/migrations (0-3 points)
- Workflow complexity (0-2 points)
- User-facing risk (0-2 points)
- Ambiguity (0-2 points)

## Track mapping
- 0-1 points: Track S (Small) - direct to implementation
- 2-4 points: Track M (Medium) - may need targeted research
- 5+ points: Track L (Large) - requires deep research
