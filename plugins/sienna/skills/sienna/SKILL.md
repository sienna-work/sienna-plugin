---
name: sienna
description: Manage Meta Ads, Google Ads, Adjust reports, analyzed ad creatives, and Instagram social publishing with the Sienna CLI. Use for ad performance, account discovery, GAQL, Meta insights, creative-pattern analysis, social account connection, guarded publishing, or provider authentication in Claude Cowork, Claude Code, or local Codex.
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

Set `SIENNA_BIN` to the resolved path and verify it with `"$SIENNA_BIN" --version`. This Skill requires Sienna 0.13.0 or newer. For an older writable host installation, obtain approval before running `sienna update`. Never download a runtime inside Cowork, and do not install another binary when a working host CLI or bundled Cowork runtime is present.

Supported surfaces are Claude Cowork Desktop, Claude Code, and local Codex CLI, Desktop, or IDE sessions. Do not claim support for ChatGPT web, Codex cloud, or another environment without a persistent local CLI and credential store.

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

Discover accessible accounts before querying them. Use [references/workflows.md](references/workflows.md) for Meta, Google, Adjust, and creative-analysis command patterns. For creative-performance questions, join live performance rows to analyzed features by ad ID rather than treating either source alone as the answer.

For a supported read-only Meta request, `"$SIENNA_BIN" ask "<natural-language request>" --json` is an optional convenience. It does not replace agent reasoning or direct commands, and its successful body follows the same contract as `meta get`.

When it returns `status: needs_input`:

1. Present `question` and `answer_contract` to the user. Do not answer on the user's behalf.
2. After the user answers, run `"$SIENNA_BIN" answer "<exact answer>" --json` as a new CLI invocation.
3. Repeat only if another `needs_input` is returned. The one pending request is profile-scoped and expires after 24 hours.

Use direct `meta get` when the natural-language backend is unavailable or the path is already known. Do not route Google, Adjust, Creative, or mutation requests through `ask`.

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

## Recover From Network Policy

Read [references/network.md](references/network.md) when a Cowork command reports DNS, connection, TLS, timeout, or egress denial. Identify the narrow domain category that failed and ask the user or administrator to allow it. Never change Cowork or organization network policy automatically.
