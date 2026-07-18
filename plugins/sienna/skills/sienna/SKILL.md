---
name: sienna
description: Manage Meta Ads, Google Ads, Adjust reports, analyzed ad creatives, and Instagram social publishing with the Sienna CLI. Use for ad performance, account discovery, GAQL, Meta insights, creative-pattern analysis, social account connection, guarded publishing, social post and follower metrics, or provider authentication in Claude Cowork, Claude Code, or local Codex.
---

# Sienna

Use Sienna as the execution layer for advertising data and guarded social publishing. Reason about the task in the agent, run the CLI with structured output, and never expose stored credentials.

## Resolve The CLI

1. When `CLAUDE_PLUGIN_ROOT` is set, run:

   ```sh
   SIENNA_BIN="$(bash "${CLAUDE_PLUGIN_ROOT}/skills/sienna/scripts/bootstrap-cowork.sh")"
   if [ -n "${CLAUDE_PLUGIN_DATA:-}" ]; then
     export SIENNA_CONFIG_DIR="${CLAUDE_PLUGIN_DATA}/sienna"
   fi
   ```

   The resolver first reuses a host `sienna` executable outside the Plugin `bin/` directory. In Cowork, where no host CLI exists, it selects the architecture-specific Linux CLI bundled in the Plugin and verifies it against the bundled release checksum. It must not download a Cowork runtime.

2. Otherwise, reuse `sienna` from `PATH` when present.

3. If neither the Plugin nor a host CLI is available, explain that the official checksum-verifying installer will download a host executable, and obtain explicit user approval before running:

   ```sh
   curl -fsSL https://get.sienna.work/install.sh | bash
   ```

Set `SIENNA_BIN` to the resolved path and verify it with `"$SIENNA_BIN" --version`. This Skill requires Sienna 0.15.0 or newer. For an older writable host installation, obtain approval before running `sienna update`. Never download a runtime inside Cowork, and do not install another binary when a working host CLI or bundled Cowork runtime is present.

Supported surfaces are Claude Cowork Desktop, Claude Code, and local Codex CLI, Desktop, or IDE sessions. Do not claim support for ChatGPT web, Codex cloud, or another environment without a persistent local CLI and credential store.

This file governs the local Plugin surface. Sienna also has a separate read-only Hosted MCP contract for approved hosted AI connections; read [references/hosted-mcp.md](references/hosted-mcp.md) before explaining how hosted and local sessions differ. Do not route local CLI work through the remote service, do not claim that Hosted MCP serves this Skill over HTTP, and do not expose a ChatGPT general-user install action before its public Plugin is approved.

## Follow The CLI Contract

- Prefer `--json`. Typed commands use `{"ok":true,"data":...}` and structured error envelopes. `meta get` and `google query` return upstream JSON directly.
- Branch on exit codes: `0` success, `2` invalid input, `3` not found, `4` auth, `5` network, `1` internal.
- Treat stdout as data and stderr as diagnostics. Never parse credential material from either stream.
- Read [references/cli-contract.md](references/cli-contract.md) before constructing an unfamiliar command.

## Authenticate Without Blocking

1. Run `"$SIENNA_BIN" auth status --json` first.
2. Start the required flow with one of:

   ```sh
   "$SIENNA_BIN" login --no-browser --persist --json
   "$SIENNA_BIN" link meta --no-browser --persist --json
   "$SIENNA_BIN" link google --no-browser --persist --json
   ```

3. Show the returned `verification_url` to the user. Never show or request a poll secret, access token, refresh token, session token, or appsecret proof.
4. After the user completes the browser flow, run the matching command with `--resume --json` once. A `pending` result is successful and preserves state; ask the user to finish the flow, then resume again. An expired, denied, or terminal error requires a new `--persist` start.
5. Recheck `auth status` before asking the user to link another provider. Login may restore previously linked providers.

Instagram connection uses the same non-blocking pattern but is managed by the
social control plane:

```sh
"$SIENNA_BIN" social account connect instagram --no-browser --persist --json
"$SIENNA_BIN" social account connect instagram --resume --json
"$SIENNA_BIN" social account list --json
```

Show the returned Sienna `verification_url` only to the user completing the
flow. Never request or display the poll proof, backend Profile ID, provider
credential, or callback state.

## Query And Analyze

For structured direct reads, discover accessible accounts before querying them. Use [references/workflows.md](references/workflows.md) for Meta, Google, Adjust, and creative-analysis command patterns. For creative-performance questions, join live performance rows to analyzed features by ad ID rather than treating either source alone as the answer.

For a multi-provider or open-ended read-only question, prefer:

```sh
"$SIENNA_BIN" ask "<complete natural-language data question>" --json
```

`ask` plans independent Meta, Google Ads, Adjust, and Creative reads in parallel and returns unsynthesized raw evidence. It may run for several minutes and waits for terminal evidence by default. Do not add `--detach` merely to avoid waiting. If the process is interrupted, resume with the exact `sienna wait <request_id> --json` command printed on stderr. Interpret `data.evidence` yourself; no `answer` field is produced.

When it returns `status: needs_input`:

1. Present `question` and `answer_contract` to the user. Do not answer on the user's behalf.
2. After the user answers, run the returned exact `answer_command`, which includes the server request id, as a new CLI invocation with `--json`.
3. Repeat only if another `needs_input` is returned. State is user-scoped, server-managed, and expires; no local pending file is required.

For `partial`, answer only from returned evidence and identify failed or missing required coverage from `gaps`. Treat `warnings` as interpretation context such as assumptions and date-range caveats. When any evidence has `complete:false`, run the returned exact `continue_command` when more pages are required; continuation skips the planner and resumes the saved provider cursor. Without a continuation command, use the available evidence first and follow each required gap's direct-read recovery only when that missing coverage is needed. Do not start another broad `sienna ask` merely to repair a known provider path.

Direct `account list`, `meta get`, Google reads, `adjust events`/`report`, and Creative `list`/`show`/`search` remain fully supported. Use them when the path is already known, or for pagination or large raw diagnostics. For a named Adjust event, resolve it with `adjust events --tokens-mapping --json`, then use the returned event id with an `_events` suffix as the report metric; never use an SDK token or bare event id as a metric. Mutation requests remain unsupported by `ask` and follow the guarded workflow below.

Ctrl-C, a broken client connection, or a polling network error does not cancel a query job. Use `sienna cancel <request_id> --dry-run --json` to inspect the target and only run the command without `--dry-run` after explicit cancellation is intended. Cancellation is cooperative, so an already-running provider read may finish while no new reads are started.

## Inspect Provider Query History

Use the CLI-only history surface to inspect Meta, Google Ads, and Adjust calls:

```sh
"$SIENNA_BIN" history list --json
"$SIENNA_BIN" history show <HISTORY_ID> --json
```

`history list` is a body-free bounded summary. Use `history show` with global
`--json` only when the full canonical request and redacted provider result are
needed. History is retained for at most 30 days by default (90-day configured
maximum) and completed rows may be evicted earlier by per-user/environment
record or byte quotas. It is secret-free and separate from the 24-hour
conversation trace: prompts, confirmation Q&A, planner messages, and final
natural-language answers are not provider history. Hosted MCP intentionally has
no history retrieval tool; do not invent or request one.

## Guard Mutations

Most provider commands are read-only. Before any command that creates, modifies, submits, pauses, resumes, or deletes data:

1. State the exact account, objects, and intended changes.
2. Run the command's `--dry-run` form when available.
3. Obtain explicit user confirmation for the final action.
4. Execute only the confirmed operation and report the resulting identifiers.

Never infer confirmation from an earlier unrelated approval.

For social work, discover opaque IDs with `social account list` and `social
post list`; never guess or parse their format. Dry-run create/cancel/retry and
disconnect before confirmation. A local-media schedule must be within six days;
use text-only content or a long-lived public media URL for later dates. Read
[references/workflows.md](references/workflows.md) for exact commands and
recovery.

Organic performance questions use the read-only metrics commands — `social
post metrics` (single post or a sorted, date-filtered list; external posts
included with `source: external`) and `social account metrics` (followers and
growth). Metrics are cumulative snapshots, need no confirmation, and require
the provider analytics add-on.

## Recover From Network Policy

Read [references/network.md](references/network.md) when a Cowork command reports DNS, connection, TLS, timeout, or egress denial. Identify the narrow domain category that failed and ask the user or administrator to allow it. Never change Cowork or organization network policy automatically.
