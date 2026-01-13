# /ask-questions

Clarify ambiguous or underspecified requirements before implementing.

## What this does

- Identifies missing information in user requests (objective, scope, constraints, environment)
- Asks 1-5 structured, easy-to-answer questions with defaults and multiple-choice options
- Pauses implementation until must-have questions are answered
- Confirms interpretation before starting work

## When to use

Use `/ask-questions` when a user request is ambiguous or underspecified:

✅ **Use when**:
- Multiple plausible interpretations exist
- Scope is unclear (which files/components affected?)
- "Done" criteria is undefined
- Constraints are missing (compatibility, performance, style)
- Environment details are ambiguous (versions, OS, tooling)
- Risk/safety implications are unclear

❌ **Don't use when**:
- Request is already clear and specific
- You can answer questions by reading existing configs/code
- It's a trivial change with obvious scope

## Usage

```
/ask-questions
```

The agent will:
1. Analyze the request for ambiguities
2. Ask 1-5 structured questions with defaults
3. Wait for answers
4. Confirm interpretation
5. Proceed with implementation

## Example

**User**: "Add a dark mode toggle"

**Agent** (after `/ask-questions`):
```
Before I implement, I need to clarify:

1) Scope?
   a) Toggle only (Recommended)
   b) Full implementation + styling

2) Persistence?
   a) LocalStorage (Recommended)
   b) API/database

Reply: `defaults` or `1b 2a`
```

## Fast-path responses

All questions include a `defaults` option so users can quickly accept recommendations:

```
Reply: defaults
```

Or specify choices:
```
Reply: 1b 2a 3c
```

## Integration with AskUserQuestion

This skill uses Claude Code's `AskUserQuestion` tool for structured option presentation when possible, providing better UX than plain text questions.

## Next steps

After questions are answered:
1. Agent confirms interpretation
2. User confirms (just say "yes" or "looks good")
3. Agent implements

---

**Note**: This is an explicit-invoke skill. The agent will not use it automatically - you must call `/ask-questions` when you detect ambiguity in your request.
