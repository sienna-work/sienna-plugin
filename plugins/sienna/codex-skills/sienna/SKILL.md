---
name: sienna
description: Use the Sienna CLI to manage advertising analytics, creative analysis, authentication, and guarded social publishing from Codex.
---

# Sienna CLI

Use Sienna only through its local CLI. Let Codex interpret the result and decide the next command. Never expose stored credentials.

This is the local Codex surface. Read [hosted-mcp.md](hosted-mcp.md) when a user asks about remote hosted connections. Do not substitute Hosted MCP for the local CLI, claim that the remote service serves this Skill, or expose approval-gated host CTAs.

## Resolve the CLI

Reuse `sienna` from `PATH`. If it is unavailable on macOS, also check `/Applications/Sienna.app/Contents/MacOS/sienna`. Set `SIENNA_BIN` to the resolved executable and verify it with `"$SIENNA_BIN" --version`.

If no executable is available, explain that the official checksum-verifying installer downloads a local CLI and obtain explicit user approval before running:

```sh
curl -fsSL https://get.sienna.work/install.sh | bash
```

This Skill requires Sienna 0.17.1 or newer. Obtain approval before updating an older writable installation with `sienna setup update`.

## Follow the CLI contract

- Prefer `--json` and treat stdout as command data and stderr as diagnostics.
- Use exit codes when branching: `0` success, `2` invalid input, `3` not found, `4` authentication, `5` network, and `1` internal failure.
- Never print, request, or parse access tokens, refresh tokens, session tokens, poll proofs, or other stored credentials.
- Use `"$SIENNA_BIN" <command> --help` when a command or option is unfamiliar.

## Authenticate

Check the current state first:

```sh
"$SIENNA_BIN" auth status --json
```

Start a required browser flow without blocking Codex:

```sh
"$SIENNA_BIN" auth login --no-browser --persist --json
"$SIENNA_BIN" auth link meta --no-browser --persist --json
"$SIENNA_BIN" auth link google --no-browser --persist --json
```

Show only the returned `verification_url`. After the user completes the browser step, run the matching command once with `--resume --json`. If it remains pending, ask the user to finish the browser step and resume again.

## Read data

For a multi-provider or open-ended read-only question, prefer `ask`. Include the complete question, providers, date range, comparisons, and requested breakdowns in one call:

```sh
"$SIENNA_BIN" ask query "<complete data question>" --json
```

<!-- ask-crew-contract:start -->
### Ask crew contract

Crew is a root execution profile inside Sienna's single Query Agent. It does not create host subagents, an agent team, specialist handoffs, or a second synthesis layer.

| Selection | Contract |
| --- | --- |
| `performance` | Broad cross-provider delivery, spend, efficiency, ranking, and trend evidence. |
| `measurement` | Attribution, conversion definitions, tracking quality, incrementality, and cross-provider discrepancy evidence. |
| `creative` | Analyzed creative features and pattern evidence, joined to live performance by stable IDs when needed. |
| Omitted `--crew` | The server selects one active profile with its low-latency router; low confidence or router failure falls back to `performance`. |
| Explicit `--crew <key>` | Fixes the root to that active profile and bypasses routing. `strategy` is known but disabled. |
| Result and resume | Returns raw `evidence`, `gaps`, `warnings`, `timing`, and typed `crew` provenance. `answer` and `continue` inherit the original crew and accept no crew override. |
| Hosted MCP | `sienna_ask` accepts the same optional top-level `crew`; omission, explicit selection, errors, provenance, and resume semantics match the CLI. |

The only CLI form is `sienna ask query "<complete question>" [--crew <crew-key>] [--detach]`. A crew key must never be a positional argument; use `--crew creative` after the complete question. A crew never synthesizes or replaces the final answer: interpret the returned raw evidence in the host agent.
<!-- ask-crew-contract:end -->

Interpret the returned evidence in Codex. When the result asks for input, present its question to the user and then run the exact returned answer command. Read failed or missing required coverage from `gaps`, and treat `warnings` as interpretation context. When the result provides a continuation command, run that exact command if more data is needed. For a partial result without continuation, use the available evidence first and follow each required gap's direct-read recovery only when that coverage is needed; do not start another broad `sienna ask query` merely to repair a known provider path.

Structured direct reads remain fully supported when the provider path is already known, or for pagination or large raw diagnostics. Prefer `sienna ads …` for paid-ads work and `sienna social …` for organic Instagram. Discover valid scopes with `ads meta accounts` or `ads google accounts`, then use `ads meta get`, Google reads, `ads adjust events`/`report`, or `ads creative` `list`/`show`/`search` as appropriate. For a named Adjust event, resolve it with `ads adjust events --tokens-mapping --json`, then use the returned event id with an `_events` suffix as the report metric; never use an SDK token or bare event id as a metric. These commands bypass AgentCore but still depend on Sienna's authenticated Query API or Creative service, so Query API or broker outages have no local provider fallback. For creative-performance analysis, either ask Sienna once or join live performance rows to analyzed features by ad ID.

## Inspect provider query history

Use the CLI-only history surface for Meta, Google Ads, and Adjust calls:

```sh
"$SIENNA_BIN" ads history list --json
"$SIENNA_BIN" ads history show <HISTORY_ID> --json
```

The list is a body-free bounded summary. Global `--json` on `ads history show`
returns the full canonical request and redacted provider result. Default maximum
retention is 30 days (configured maximum 90 days), but per-user/environment
record or byte quotas may evict completed rows earlier. Provider history is
secret-free and separate from the 24-hour conversation trace; it excludes
prompts, confirmation Q&A, planner messages, and final natural-language
answers. Hosted MCP intentionally exposes no history retrieval tool.

## Inspect Ask history

Use the CLI-only Ask history surface for terminal Ask meta (prompt, status,
timing, gaps/warnings summary). Evidence bodies stay in provider query history
and link by `request_id` / `root_request_id`:

```sh
"$SIENNA_BIN" ask history list --json
"$SIENNA_BIN" ask history show <REQUEST_ID> --json
```

Ask history is written only for terminal statuses
(`completed`/`partial`/`failed`/`cancelled`), not for `needs_input`. It uses the
same 30-day default retention family as provider history but a separate quota
counter. New rows expose nullable `requested_crew`, `resolved_crew`,
`routing_source`, and `catalog_version`; null fields on a legacy row must not be
inferred from its prompt. It does not replace conversation-trace. Hosted MCP
has no Ask history tool.

## Guard changes

Before a command that creates, modifies, publishes, pauses, resumes, cancels, disconnects, or deletes anything:

1. State the exact target and intended change.
2. Run the command with `--dry-run` when available.
3. Obtain explicit user confirmation.
4. Execute only the confirmed command and report its result.

Never reuse confirmation from an unrelated earlier action.
