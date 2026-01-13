# Bead Review
QA/adversarial audit of bead decomposition.

## What this does
- Reviews beads against the Technical Design Document for completeness
- Identifies atomicity and dependency issues
- Checks context sufficiency for autonomous execution
- Flags risk and hallucination guardrails

## Usage
Provide both:
1. The polished Technical Design Document from Stage 2
2. The beads output from Stage 3

The agent will audit for:
- Coverage completeness (every design requirement maps to ≥1 bead)
- Atomicity (single responsibility per bead)
- Dependencies (no circular or missing prerequisites)
- Context sufficiency (no implicit references)
- Risk mitigation (version-sensitive APIs, external service failures)

## Output
Either `APPROVED` or detailed issues with fixes and revised beads.
