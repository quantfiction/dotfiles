# Swarm Orchestrator Skill

Control and monitor the Swarm Orchestrator service via the HTTP API.

## Overview

The Swarm Orchestrator coordinates parallel Claude Code agents working on beads (tasks with dependencies). This skill provides commands to start, stop, monitor, and manage swarm execution without using tmux.

**Base URL:** `http://localhost:3100` (configurable via `SWARM_BASE_URL` environment variable)

## Commands

All commands use the wrapper script at `scripts/swarm.sh`. This is preferred over raw curl commands.

### status

Get basic swarm status.

```bash
./scripts/swarm.sh status
```

**API:** `GET /swarm/status`

**Response fields:**
- `status` - Current state: `idle`, `starting`, `running`, `stopping`, `stopped`
- `label` - Bead label filter for current run
- `progress.total` - Total beads to process
- `progress.completed` - Beads completed
- `progress.inProgress` - Beads currently being worked
- `progress.blocked` - Beads blocked by dependencies
- `agents.active` - Currently running agents
- `agents.total` - Total agents spawned this run

### state

Get full aggregate swarm state including agent details and recent events.

```bash
./scripts/swarm.sh state
```

**API:** `GET /swarm`

Returns comprehensive state including:
- Swarm ID, status, label, timing
- Full stats breakdown
- All agent details (bead, state, PID, activity)
- Recent event buffer

### start

Start a swarm run for beads with a specific label.

```bash
./scripts/swarm.sh start <label>
```

**API:** `POST /swarm/start`

**Request body:**
```json
{"label": "<label>"}
```

**Important limitation:** The route accepts a `config` parameter but the current implementation ignores it. Only `label` is used. See `services/swarm-orchestrator/src/api/routes/control.ts`.

**Error responses:**
- `400` - Missing or empty label
- `409` - Swarm already running (must stop first)
- `500` - Orchestrator not initialized

### stop

Graceful stop - signals agents to complete current work then exit.

```bash
./scripts/swarm.sh stop
```

**API:** `POST /swarm/stop`

Returns `{"stopped": true}` when complete. Agents finish their current task before terminating.

### force-stop

Immediate termination - kills all agents without waiting.

```bash
./scripts/swarm.sh force-stop
```

**API:** `POST /swarm/force-stop`

Use when graceful stop is taking too long or agents are stuck.

### escalations

List pending escalations requiring human attention.

```bash
./scripts/swarm.sh escalations
```

**API:** `GET /swarm/escalations`

Escalations include:
- Merge conflicts
- Agent failures
- Dependency cycles
- Other issues requiring manual resolution

### resolve-escalation

Mark an escalation as resolved after manual intervention.

```bash
./scripts/swarm.sh resolve-escalation <id> --yes
```

**API:** `POST /swarm/escalations/:id/resolve`

**Requires `--yes` flag** for non-interactive use. Without it, prompts for confirmation.

### refresh

Reload bead state from the `bd` CLI.

```bash
./scripts/swarm.sh refresh
```

**API:** `POST /swarm/refresh`

Use after manually updating beads outside the orchestrator (e.g., closing beads via `bd close`).

### health

Check if the orchestrator is ready to accept work.

```bash
./scripts/swarm.sh health
```

**API:** `GET /swarm/health/ready`

**Exit codes:**
- `0` - Ready (all checks pass)
- `1` - Not ready (one or more checks failing)

Checks performed:
- `bd-cli` - Beads CLI available
- `git-cli` - Git available
- `worktree-root` - Worktree directory exists

## Global Options

All commands accept these options:

| Option | Description | Default |
|--------|-------------|---------|
| `--base-url <url>` | Override API base URL | `http://localhost:3100` |
| `--format <text\|json>` | Output format | `text` |
| `--timeout-ms <ms>` | Request timeout | `5000` |
| `--yes` | Skip confirmation prompts | (prompts enabled) |
| `-h, --help` | Show help | |

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success |
| `1` | Failure (network error, HTTP error, timeout) |
| `2` | Usage error (invalid arguments) |

## Error Handling

### Network unreachable

```
Error: Network error: could not connect to http://localhost:3100/swarm/status
```

Exit code: `1`

**Resolution:** Ensure the orchestrator is running (`npm run dev` in `services/swarm-orchestrator`).

### Request timeout

```
Error: Request timed out after 5000ms
```

Exit code: `1`

**Resolution:** Increase timeout with `--timeout-ms`, or check if orchestrator is overloaded.

### HTTP 4xx/5xx errors

```
Error: HTTP 409: Swarm already running
```

Exit code: `1`

The error message includes the HTTP status code and response body/error message.

### Swarm already running (409)

When calling `start` while a swarm is active:

```
Error: HTTP 409: Swarm already running
```

**Resolution:** Stop the current swarm first with `stop` or `force-stop`.

## Examples

### Basic workflow

```bash
# Check orchestrator is ready
./scripts/swarm.sh health

# Start swarm for sprint-1 beads
./scripts/swarm.sh start sprint-1

# Monitor progress
./scripts/swarm.sh status

# Get detailed state
./scripts/swarm.sh state

# Check for problems
./scripts/swarm.sh escalations

# Graceful stop
./scripts/swarm.sh stop
```

### JSON output for scripting

```bash
# Get status as JSON
./scripts/swarm.sh --format json status

# Use with jq
./scripts/swarm.sh --format json state | jq '.stats.completedBeads'
```

### Non-interactive automation

```bash
# Resolve escalation without prompt
./scripts/swarm.sh resolve-escalation esc-123 --yes

# Custom timeout for slow networks
./scripts/swarm.sh --timeout-ms 30000 state
```

### Environment variable configuration

```bash
export SWARM_BASE_URL="http://192.168.1.100:3100"
./scripts/swarm.sh status  # Uses remote server
```

## Related Documentation

- `services/swarm-orchestrator/README.md` - Full API reference including WebSocket streaming
- `scripts/swarm.sh` - Wrapper script source code
