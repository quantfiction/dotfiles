/**
 * Agent Mode Extension
 *
 * Three modes controlling tool access:
 * - ask:   read-only, no file modifications (chat/explore)
 * - plan:  read + markdown editing only (writing plans)
 * - build: full tool access (implementation)
 *
 * Shift+Tab to cycle, /ask /plan /build to set directly.
 *
 * Design philosophy: prevent obvious filesystem mutations (writes, deletes,
 * git push, package installs) without being so restrictive that routine
 * read operations require workarounds. We check every command in a chain
 * (&&, ||, ;, |) but allow interpreters for inline expressions, SQL
 * comparisons with >, jq filters, etc.
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { isToolCallEventType } from "@mariozechner/pi-coding-agent";

const MODES = ["ask", "plan", "build"] as const;
type Mode = (typeof MODES)[number];

const MODE_LABELS: Record<Mode, string> = {
	ask: "🔍 ask",
	plan: "📋 plan",
	build: "🔨 build",
};

// Tools to REMOVE per mode (blacklist approach).
// Everything else (including extension-registered tools like subagent, web, etc.) is allowed.
const ASK_DENY = new Set(["edit", "write"]);
const PLAN_DENY = new Set<string>(); // plan allows everything
const BUILD_DENY = new Set<string>(); // build allows everything

function getDenyList(mode: Mode): Set<string> {
	switch (mode) {
		case "ask":
			return ASK_DENY;
		case "plan":
			return PLAN_DENY;
		case "build":
			return BUILD_DENY;
	}
}

function isMarkdownPath(path: string): boolean {
	const p = path.replace(/^@/, "").trim();
	return /\.md$/i.test(p) || /\.mdx$/i.test(p);
}

// ---------------------------------------------------------------------------
// Bash command analysis
//
// Approach: check every command in a chain/pipe against a blocklist of
// mutating commands. Unknown commands are allowed — the goal is to catch
// obvious mutations, not to sandbox arbitrary execution. This avoids
// false positives on jq expressions, SQL comparisons, python -c, etc.
// ---------------------------------------------------------------------------

/**
 * Commands and patterns that mutate filesystem, processes, or system state.
 * Checked against each segment in a command chain.
 */
const MUTATING_COMMANDS: RegExp[] = [
	// filesystem mutations
	/^rm\b/, /^mv\b/, /^cp\b/, /^mkdir\b/, /^rmdir\b/, /^touch\b/,
	/^chmod\b/, /^chown\b/, /^chgrp\b/, /^ln\b/,
	/^install\b/,  // coreutils install
	// editors (interactive, but block in case of scripted use)
	/^nano\b/, /^vi\b/, /^vim\b/, /^emacs\b/,
	// git mutations
	/^git\s+(add|commit|push|merge|rebase|reset|checkout\s+-b|switch\s+-c|branch\s+-[dDmM]|stash(?!\s+list|\s+show)|cherry-pick|revert|tag\s+\S|clean|gc|am|format-patch)\b/,
	// package managers — install/modify
	/^npm\s+(install|uninstall|update|publish|init|link|ci|pkg)\b/, /^npx\b/,
	/^yarn\s+(add|remove|install)\b/,
	/^pnpm\s+(add|remove|install)\b/,
	/^pip\s+(install|uninstall)\b/,
	/^uv\s+(add|remove|sync|lock|pip\s+install|pip\s+uninstall)\b/,
	/^cargo\s+(install|build|run|publish|add|remove)\b/,
	/^go\s+(install|build|run|get)\b/,
	// process control
	/^kill\b/, /^pkill\b/, /^killall\b/,
	/^nohup\b/, /^disown\b/,
	/^sudo\b/,
	// containers
	/^docker\s+(run|rm|stop|kill|build|push|pull|exec|create|compose)\b/,
	/^docker-compose\b/,
	/^podman\s+(run|rm|stop|kill|build|push|pull|exec|create)\b/,
	// service management
	/^systemctl\s+(start|stop|restart|enable|disable|mask|unmask|daemon-reload)\b/,
	/^service\s+\S+\s+(start|stop|restart)\b/,
	// dangerous tools
	/^dd\b/, /^mkfs\b/, /^fdisk\b/, /^parted\b/,
	/^iptables\b/, /^ufw\b/,
	/^crontab\s+-[er]\b/,
	// in-place file modification
	/^sed\s.*-i\b/, /^sed\s+-i\b/,
	// tee writes to files
	/^tee\b/,
];

/**
 * Patterns that indicate output redirection to a file.
 * More precise than the previous version: requires whitespace or line
 * start before > or >>, and avoids matching >=, =>, or > inside quotes.
 */
function hasFileRedirect(segment: string): boolean {
	// Strip quoted strings to avoid matching > inside them
	const stripped = segment
		.replace(/"(?:[^"\\]|\\.)*"/g, '""')
		.replace(/'[^']*'/g, "''");

	// Match > or >> preceded by space/start, followed by a path-like target
	// But NOT >= (comparison) or => (arrow) or >& (fd redirect)
	return /(?:^|\s)>{1,2}\s*(?![>=&\s])/.test(stripped);
}

/** SQL that modifies data. */
const MUTATING_SQL = /\b(INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|TRUNCATE|REPLACE)\b/i;

/**
 * Shell constructs that can bypass per-command checks.
 */
const SHELL_ESCAPE_PATTERNS: Array<{ pattern: RegExp; label: string }> = [
	{ pattern: /\beval\b/, label: "eval" },
	{ pattern: /\bexec\s/, label: "exec" },
	{ pattern: /\bbash\s+-c\b/, label: "bash -c" },
	{ pattern: /\bsh\s+-c\b/, label: "sh -c" },
	{ pattern: /\bzsh\s+-c\b/, label: "zsh -c" },
];

/**
 * Split a command string into individual segments across
 * chain operators (&&, ||, ;) and pipes (|).
 */
function splitCommands(cmdStr: string): string[] {
	const segments: string[] = [];
	for (const chain of cmdStr.split(/\s*(?:&&|\|\||;)\s*/)) {
		for (const pipe of chain.split(/\s*\|\s*/)) {
			const trimmed = pipe.trim();
			if (trimmed) segments.push(trimmed);
		}
	}
	return segments;
}

/**
 * Extract the base command from a segment, stripping env vars,
 * wrappers, and path prefixes.
 */
function extractCommand(segment: string): { cmd: string; rest: string } {
	let s = segment;

	// Strip leading variable assignments: FOO=bar command ...
	s = s.replace(/^(?:[A-Za-z_][A-Za-z0-9_]*=[^\s]*\s+)+/, "");

	// Strip timing/priority wrappers
	for (const wrapper of ["time", "timeout", "nice", "ionice"]) {
		const re = new RegExp(`^${wrapper}\\s+(?:-\\S+\\s+)*`);
		if (re.test(s)) s = s.replace(re, "");
	}

	const parts = s.split(/\s+/);
	const raw = parts[0] || "";
	const rest = parts.slice(1).join(" ");

	// Handle path-qualified: /usr/bin/grep -> grep, .venv/bin/python3 -> python3
	const base = raw.split("/").pop() || raw;

	return { cmd: base, rest };
}

/**
 * Check if a single command segment is mutating.
 * Returns null if allowed, or a reason string if blocked.
 */
function checkSegment(segment: string): string | null {
	// File output redirection
	if (hasFileRedirect(segment)) {
		return `output redirection writes to disk`;
	}

	const { cmd, rest } = extractCommand(segment);
	if (!cmd) return null;

	// Check against mutating command patterns
	// We test the full "cmd rest" string so patterns like "git push" work
	const fullCmd = `${cmd} ${rest}`.trim();
	for (const pattern of MUTATING_COMMANDS) {
		if (pattern.test(fullCmd)) {
			return `"${fullCmd.slice(0, 60)}" is a mutating command`;
		}
	}

	// sqlite3: block mutating SQL
	if (cmd === "sqlite3" && MUTATING_SQL.test(rest)) {
		return `sqlite3 with mutating SQL`;
	}

	// Interpreters running script files (not inline) — block
	// python/python3/node script.py can do anything
	if ((cmd === "python" || cmd === "python3") && rest && !rest.startsWith("-")) {
		return `"${cmd} ${rest.split(/\s/)[0]}" runs a script file`;
	}
	if (cmd === "node" && rest && !rest.startsWith("-")) {
		return `"node ${rest.split(/\s/)[0]}" runs a script file`;
	}

	// Everything else is allowed — jq, awk, python -c, node -e,
	// sqlite3 SELECT, curl, grep, unknown tools, etc.
	return null;
}

/**
 * Check whether a full bash command string is safe for read-only mode.
 * Returns null if allowed, or a reason string if blocked.
 */
function checkBashCommand(fullCmd: string): string | null {
	const trimmed = fullCmd.trim();

	// Shell escape patterns that bypass per-command checks
	for (const { pattern, label } of SHELL_ESCAPE_PATTERNS) {
		if (pattern.test(trimmed)) {
			return `${label} can execute arbitrary code`;
		}
	}

	// Check every segment in the chain
	const segments = splitCommands(trimmed);
	for (const segment of segments) {
		const reason = checkSegment(segment);
		if (reason) return reason;
	}

	return null;
}

// ---------------------------------------------------------------------------
// Extension entry point
// ---------------------------------------------------------------------------

export default function agentMode(pi: ExtensionAPI): void {
	let currentMode: Mode = "build";

	function applyMode(ctx: ExtensionContext): void {
		const deny = getDenyList(currentMode);
		const allowed = pi.getAllTools().map(t => t.name).filter(n => !deny.has(n));
		pi.setActiveTools(allowed);
		const theme = ctx.ui.theme;
		const colors: Record<Mode, string> = {
			ask: theme.fg("accent", MODE_LABELS.ask),
			plan: theme.fg("warning", MODE_LABELS.plan),
			build: theme.fg("success", MODE_LABELS.build),
		};
		ctx.ui.setStatus("agent-mode", colors[currentMode]);
		pi.appendEntry("agent-mode", { mode: currentMode });
	}

	function cycleMode(ctx: ExtensionContext): void {
		const idx = MODES.indexOf(currentMode);
		currentMode = MODES[(idx + 1) % MODES.length];
		applyMode(ctx);
		ctx.ui.notify(`Mode: ${MODE_LABELS[currentMode]}`, "info");
	}

	function setMode(mode: Mode, ctx: ExtensionContext): void {
		currentMode = mode;
		applyMode(ctx);
		ctx.ui.notify(`Mode: ${MODE_LABELS[currentMode]}`, "info");
	}

	// /ask, /plan, /build commands
	for (const mode of MODES) {
		pi.registerCommand(mode, {
			description: `Switch to ${mode} mode (${MODE_LABELS[mode]})`,
			handler: async (_args, ctx) => setMode(mode, ctx),
		});
	}

	// Shift+Tab to cycle modes
	pi.registerShortcut("f2", {
		description: "Cycle agent mode (ask > plan > build)",
		handler: async (ctx) => cycleMode(ctx),
	});

	// Gate tool calls based on mode
	pi.on("tool_call", async (event) => {
		if (currentMode === "build") return;

		// ask: block all writes/edits
		if (currentMode === "ask") {
			if (event.toolName === "edit" || event.toolName === "write") {
				return { block: true, reason: "Ask mode: file modifications are disabled. Use /build to enable." };
			}
		}

		// plan: only markdown writes/edits
		if (currentMode === "plan") {
			if (event.toolName === "write" && isToolCallEventType("write", event)) {
				if (!isMarkdownPath(event.input.path)) {
					return { block: true, reason: `Plan mode: can only write .md/.mdx files. Use /build for full access.` };
				}
			}
			if (event.toolName === "edit" && isToolCallEventType("edit", event)) {
				if (!isMarkdownPath(event.input.path)) {
					return { block: true, reason: `Plan mode: can only edit .md/.mdx files. Use /build for full access.` };
				}
			}
		}

		// ask + plan: bash must not mutate
		if (event.toolName === "bash" && isToolCallEventType("bash", event)) {
			const reason = checkBashCommand(event.input.command);
			if (reason) {
				return { block: true, reason: `${MODE_LABELS[currentMode]} mode — blocked: ${reason}. Use /build to enable.` };
			}
		}
	});

	// Inject mode context
	pi.on("before_agent_start", async () => {
		if (currentMode === "build") return;

		const modeInstructions: Record<string, string> = {
			ask: `[MODE: ask — observe and advise]
You are in ask mode. Your role is to help the user understand, investigate, and reason about
the codebase — not to change it. Read files, explore structure, run queries, trace data flows,
and explain what you find. When the user asks for a fix or feature, describe what you would do
and where, but do not make the changes. If your analysis naturally leads to "and here's the fix,"
present it as a recommendation ("I would change X in Y") rather than reaching for edit/write.

The edit and write tools are disabled. Bash commands that modify files, git state, packages, or
processes will be blocked. Reading, searching, and running inline expressions are all fine.
When the user is ready to act on your recommendations, they can switch to /build.`,
			plan: `[MODE: plan — design and document]
You are in plan mode. Your role is to help the user think through problems and capture decisions
in markdown documents. Read anything, write .md/.mdx files, and focus on producing clear plans,
designs, and specifications rather than code. When implementation details come up, document them
as actionable steps in the plan rather than writing the code directly.

Only .md/.mdx files can be created or edited. Bash commands that modify files, git state,
packages, or processes will be blocked. When the plan is ready for implementation, use /build.`,
		};

		return {
			message: {
				customType: "agent-mode-context",
				content: modeInstructions[currentMode],
				display: false,
			},
		};
	});

	// Filter stale mode context from previous turns
	pi.on("context", async (event) => {
		return {
			messages: event.messages.filter((m) => {
				const msg = m as any;
				return msg.customType !== "agent-mode-context";
			}),
		};
	});

	// Restore state on session start
	pi.on("session_start", async (_event, ctx) => {
		const entries = ctx.sessionManager.getEntries();
		const last = entries
			.filter((e: any) => e.type === "custom" && e.customType === "agent-mode")
			.pop() as any;

		if (last?.data?.mode && MODES.includes(last.data.mode)) {
			currentMode = last.data.mode;
		}

		applyMode(ctx);
	});
}
