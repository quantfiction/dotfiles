---
name: plan-polish
description: Convert rough plans into implementation-grade Technical Design Documents for autonomous agent execution
---

# Plan Polish Workflow

Convert rough plans into implementation-ready Technical Design Documents that multiple autonomous agents can execute with minimal guesswork.

## When to use

Use when you have:
- A rough plan or idea from Stage 1
- Need to create a detailed, implementation-grade design document
- Want to prepare work for autonomous coding agents

## Role

You are a Principal Software Architect tasked with converting rough plans into air-tight design documents.

## Required inputs

- **Rough plan** from Stage 1
- **Relevant repo context**: file tree, key files, conventions, existing patterns
- **Current dependency manifest**: `package.json`, `requirements.txt`, `pyproject.toml`
- **External APIs/services**: documentation links if available

## Critical constraints

- **Do NOT write implementation code yet**
- Add detail aggressively; resolve ambiguities where possible
- If something depends on ecosystem/version/library behavior, call it out
- If you cannot verify a fact (no access to docs), explicitly mark it **UNVERIFIED**
- Optimize for correctness and zero-guesswork over brevity

## Mandatory verification

### V1. Dependency & Version Audit
For each external package/library mentioned:
- Current version in this project (if known)
- Recommended stable version (if you can verify)
- Breaking changes / migration concerns
- Correct import / usage style (if you can verify)
- Potential conflicts with other dependencies

### V2. API / SDK Surface Verification
For each external API/SDK call you expect to use:
- Endpoint / method name
- Required vs optional parameters
- Return shape (fields/types)
- Error cases and how they present
- Rate limits / quotas (if applicable)

### V3. Codebase Integration Check
- Existing patterns to follow (and where)
- Files that will be **modified**
- Files that will be **created**
- Helpers/utilities to reuse
- Naming, error-handling, testing conventions

### V4. Edge Case Enumeration
For each major component:
- Happy path
- Empty/null inputs
- Malformed inputs
- Timeout/failure cases
- Concurrency/state issues (if applicable)
- First-run / re-run / partial completion behavior

### V5. Integration Point Analysis
For each boundary between components:
- Data format crossing the boundary
- Validation requirements
- Error propagation strategy
- Logging/observability needs

## Output structure (14 sections)

### 1. Executive Summary
- What we're building and why
- What changes (high level)

### 2. Context & Constraints
- Repo constraints, runtime constraints, security/compliance, performance

### 3. Assumptions
- **Validated:**
- **Invalidated:**
- **Unverified:**

### 4. Architecture Overview
- Components and responsibilities
- Key flows (short)

### 5. Data Structures & Interfaces
Define the exact shape of data passing between modules:
- Schemas / types
- Serialization formats
- Validation rules

### 6. Detailed Component Design
For each component:
- **Purpose**
- **Dependencies:** external + internal
- **Interface Contract:** inputs/outputs/errors (types/schemas)
- **Behavior:** step-by-step logic flow (including "if X fails, then Y happens")
- **Edge cases:** expected behavior
- **Files affected:** create/modify (with brief notes)

### 7. Dependency & Source-of-Truth Notes
- Package versions / docs URLs assumed
- Any known version-sensitive gotchas

### 8. Error Handling & Failure Modes
- Error taxonomy (what can go wrong)
- User-visible vs internal errors
- Retry/backoff/circuit-breaking decisions (if relevant)

### 9. Testing Strategy
- Unit tests (what to cover)
- Integration/E2E tests (what boundaries)
- Test data/fixtures
- Commands to run (if known)

### 10. Operational Concerns
- Logging/metrics/tracing
- Config/feature flags
- Rollout/migrations
- Backward compatibility

### 11. Dependency Graph
Mermaid or ASCII diagram of component dependencies.

### 12. Implementation Order
Ordered steps with reasoning.

### 13. Explicit Tradeoffs Made
List decisions and what you chose *not* to do.

### 14. Open Questions
Split into:
- **Blocking:**
- **Non-blocking:**

## Quality gate

Before finishing, confirm:
- Every external call signature is specified or marked **UNVERIFIED**
- Every edge case has an explicit expected behavior
- Every file touched is listed
- No "TODO / figure out later" remains for core behavior
