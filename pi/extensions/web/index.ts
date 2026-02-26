/**
 * Web Extension
 *
 * Three tools:
 * - web_search: Search via Exa API (paid per search)
 * - web_fetch: Fetch URLs for free via markdown.new → fallback to direct fetch + turndown
 * - web_ask: Ask Perplexity a question, get a researched answer with citations
 *
 * Env vars: EXA_API_KEY, PERPLEXITY_API_KEY
 */

import type { ExtensionAPI } from "@mariozechner/pi-coding-agent";
import { truncateHead, DEFAULT_MAX_BYTES, DEFAULT_MAX_LINES, formatSize } from "@mariozechner/pi-coding-agent";
import { Type } from "@sinclair/typebox";
import { StringEnum } from "@mariozechner/pi-ai";
import TurndownService from "turndown";

const turndown = new TurndownService({
	headingStyle: "atx",
	codeBlockStyle: "fenced",
	hr: "---",
	bulletListMarker: "-",
});

function stripJunk(html: string): string {
	return html
		.replace(/<script[\s\S]*?<\/script>/gi, "")
		.replace(/<style[\s\S]*?<\/style>/gi, "")
		.replace(/<nav[\s\S]*?<\/nav>/gi, "")
		.replace(/<footer[\s\S]*?<\/footer>/gi, "")
		.replace(/<noscript[\s\S]*?<\/noscript>/gi, "")
		.replace(/<!--[\s\S]*?-->/g, "");
}

function htmlToMarkdown(html: string): string {
	return turndown.turndown(stripJunk(html));
}

function truncate(text: string) {
	const result = truncateHead(text, { maxLines: DEFAULT_MAX_LINES, maxBytes: DEFAULT_MAX_BYTES });
	return {
		content: result.content,
		wasTruncated: result.truncated,
		totalBytes: result.totalBytes,
		totalLines: result.totalLines,
	};
}

/**
 * Fetch a URL as markdown. Strategy:
 * 1. markdown.new proxy (free, returns clean markdown)
 * 2. Direct fetch + turndown conversion (fallback)
 */
async function fetchAsMarkdown(url: string, signal?: AbortSignal): Promise<{ content: string; source: string }> {
	// Strategy 1: markdown.new
	try {
		const mdUrl = `https://markdown.new/${url}`;
		const resp = await fetch(mdUrl, {
			headers: { "User-Agent": "Mozilla/5.0 (compatible; pi-agent/1.0)" },
			signal,
			redirect: "follow",
		});
		const text = await resp.text();
		// markdown.new returns 404 status but still has content — check for actual markdown
		if (text && text.includes("Markdown Content:")) {
			// Extract just the markdown content after the header
			const match = text.match(/Markdown Content:\n([\s\S]*)/);
			if (match) {
				return { content: match[1].trim(), source: "markdown.new" };
			}
		}
		if (text && text.length > 100 && !text.startsWith("<!DOCTYPE") && !text.startsWith("<html")) {
			return { content: text, source: "markdown.new" };
		}
	} catch (_) {
		// Fall through to next strategy
	}

	// Strategy 2: Direct fetch + turndown
	const resp = await fetch(url, {
		headers: {
			"User-Agent": "Mozilla/5.0 (compatible; pi-agent/1.0)",
			Accept: "text/html,text/plain,*/*",
		},
		signal,
		redirect: "follow",
	});

	if (!resp.ok) {
		throw new Error(`HTTP ${resp.status} ${resp.statusText}`);
	}

	const contentType = resp.headers.get("content-type") ?? "";
	const body = await resp.text();

	if (contentType.includes("text/plain") || contentType.includes("text/markdown")) {
		return { content: body, source: "direct (plain text)" };
	}

	return { content: htmlToMarkdown(body), source: "direct (turndown)" };
}

export default function webExtension(pi: ExtensionAPI): void {
	// ── web_search ──────────────────────────────────────────────────────
	pi.registerTool({
		name: "web_search",
		label: "Web Search",
		description:
			"Search the web using Exa. Returns titles, URLs, and descriptions. Use web_fetch to get full content from result URLs. Requires EXA_API_KEY.",
		parameters: Type.Object({
			query: Type.String({ description: "Search query" }),
			count: Type.Optional(Type.Number({ description: "Number of results (default 5, max 20)", minimum: 1, maximum: 20 })),
			type: Type.Optional(StringEnum(["auto", "neural", "keyword"] as const, { description: "Search type (default auto)" })),
			category: Type.Optional(StringEnum([
				"company", "research paper", "news", "pdf", "github", "tweet", "personal site", "linkedin profile", "financial report",
			] as const, { description: "Filter to a specific content category" })),
			includeDomains: Type.Optional(Type.Array(Type.String(), { description: "Only include results from these domains" })),
			excludeDomains: Type.Optional(Type.Array(Type.String(), { description: "Exclude results from these domains" })),
		}),

		async execute(_toolCallId, params, signal) {
			const apiKey = process.env.EXA_API_KEY;
			if (!apiKey) {
				return { content: [{ type: "text", text: "Error: EXA_API_KEY environment variable is not set." }], isError: true };
			}

			const body: any = {
				query: params.query,
				numResults: params.count ?? 5,
				type: params.type ?? "auto",
			};

			if (params.category) body.category = params.category;
			if (params.includeDomains) body.includeDomains = params.includeDomains;
			if (params.excludeDomains) body.excludeDomains = params.excludeDomains;

			try {
				const response = await fetch("https://api.exa.ai/search", {
					method: "POST",
					headers: { "x-api-key": apiKey, "Content-Type": "application/json" },
					body: JSON.stringify(body),
					signal,
				});

				if (!response.ok) {
					const text = await response.text();
					return { content: [{ type: "text", text: `Exa search error ${response.status}: ${text}` }], isError: true };
				}

				const data = (await response.json()) as any;
				const results = data.results ?? [];

				if (results.length === 0) {
					return {
						content: [{ type: "text", text: `No results found for "${params.query}".` }],
						details: { query: params.query, results: [], cost: data.costDollars?.total },
					};
				}

				const formatted = results.map((r: any, i: number) => {
					let entry = `${i + 1}. **${r.title}**\n   ${r.url}`;
					if (r.publishedDate) entry += `\n   Published: ${r.publishedDate}`;
					if (r.author) entry += `\n   Author: ${r.author}`;
					return entry;
				}).join("\n\n");

				return {
					content: [{ type: "text", text: formatted }],
					details: {
						query: params.query,
						count: results.length,
						cost: data.costDollars?.total,
						urls: results.map((r: any) => r.url),
					},
				};
			} catch (err: any) {
				if (err.name === "AbortError") return { content: [{ type: "text", text: "Search cancelled." }] };
				return { content: [{ type: "text", text: `Search error: ${err.message}` }], isError: true };
			}
		},
	});

	// ── web_fetch ───────────────────────────────────────────────────────
	pi.registerTool({
		name: "web_fetch",
		label: "Web Fetch",
		description:
			"Fetch a web page and return its content as markdown. Free — uses markdown.new proxy with direct fetch fallback. Output truncated to ~50KB.",
		parameters: Type.Object({
			url: Type.String({ description: "URL to fetch" }),
		}),

		async execute(_toolCallId, params, signal) {
			const url = params.url.replace(/^@/, "");

			try {
				const { content, source } = await fetchAsMarkdown(url, signal);
				const { content: truncated, wasTruncated, totalBytes, totalLines } = truncate(content);

				let result = truncated;
				if (wasTruncated) {
					result += `\n\n[Content truncated: showing first ${DEFAULT_MAX_LINES} lines / ${formatSize(DEFAULT_MAX_BYTES)} of ${totalLines} lines / ${formatSize(totalBytes)}]`;
				}

				return {
					content: [{ type: "text", text: result }],
					details: { url, source, truncated: wasTruncated, originalSize: totalBytes },
				};
			} catch (err: any) {
				if (err.name === "AbortError") return { content: [{ type: "text", text: "Fetch cancelled." }] };
				return { content: [{ type: "text", text: `Fetch error: ${err.message}` }], isError: true };
			}
		},
	});

	// ── web_ask ─────────────────────────────────────────────────────────
	pi.registerTool({
		name: "web_ask",
		label: "Web Ask",
		description:
			"Ask a question and get a researched answer with citations from Perplexity. Good for factual questions, current events, and research. Requires PERPLEXITY_API_KEY.",
		parameters: Type.Object({
			question: Type.String({ description: "Question to research" }),
			model: Type.Optional(StringEnum(["sonar", "sonar-pro", "sonar-reasoning", "sonar-reasoning-pro"] as const, {
				description: "Perplexity model (default sonar). sonar-pro for deeper research, sonar-reasoning for complex analysis.",
			})),
		}),

		async execute(_toolCallId, params, signal) {
			const apiKey = process.env.PERPLEXITY_API_KEY;
			if (!apiKey) {
				return { content: [{ type: "text", text: "Error: PERPLEXITY_API_KEY environment variable is not set." }], isError: true };
			}

			try {
				const response = await fetch("https://api.perplexity.ai/chat/completions", {
					method: "POST",
					headers: {
						Authorization: `Bearer ${apiKey}`,
						"Content-Type": "application/json",
					},
					body: JSON.stringify({
						model: params.model ?? "sonar",
						messages: [{ role: "user", content: params.question }],
					}),
					signal,
				});

				if (!response.ok) {
					const text = await response.text();
					return { content: [{ type: "text", text: `Perplexity error ${response.status}: ${text}` }], isError: true };
				}

				const data = (await response.json()) as any;
				const answer = data.choices?.[0]?.message?.content ?? "No answer returned.";
				const citations = data.citations ?? [];

				let result = answer;
				if (citations.length > 0) {
					result += "\n\n**Sources:**\n" + citations.map((c: string, i: number) => `${i + 1}. ${c}`).join("\n");
				}

				return {
					content: [{ type: "text", text: result }],
					details: {
						model: params.model ?? "sonar",
						citations,
						cost: data.usage?.cost?.total_cost,
					},
				};
			} catch (err: any) {
				if (err.name === "AbortError") return { content: [{ type: "text", text: "Ask cancelled." }] };
				return { content: [{ type: "text", text: `Ask error: ${err.message}` }], isError: true };
			}
		},
	});

	// ── Status ──────────────────────────────────────────────────────────
	pi.on("session_start", async (_event, ctx) => {
		const hasExa = !!process.env.EXA_API_KEY;
		const hasPplx = !!process.env.PERPLEXITY_API_KEY;
		const missing = [!hasExa && "EXA_API_KEY", !hasPplx && "PERPLEXITY_API_KEY"].filter(Boolean);
		if (missing.length > 0) {
			ctx.ui.setStatus("web", ctx.ui.theme.fg("warning", `⚠ missing: ${missing.join(", ")}`));
		}
	});
}
