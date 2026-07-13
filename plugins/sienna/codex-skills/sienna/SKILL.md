---
name: sienna
description: Use the Sienna CLI to manage advertising analytics, creative analysis, authentication, and guarded social publishing from Codex.
---

# Sienna CLI

Use Sienna only through its local CLI. Let Codex interpret the result and decide the next command. Never expose stored credentials.

## Resolve the CLI

Reuse `sienna` from `PATH`. If it is unavailable on macOS, also check `/Applications/Sienna.app/Contents/MacOS/sienna`. Set `SIENNA_BIN` to the resolved executable and verify it with `"$SIENNA_BIN" --version`.

If no executable is available, explain that the official checksum-verifying installer downloads a local CLI and obtain explicit user approval before running:

```sh
curl -fsSL https://get.sienna.work/install.sh | bash
```

This Skill requires Sienna 0.15.0 or newer. Obtain approval before updating an older writable installation with `sienna update`.

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
"$SIENNA_BIN" login --no-browser --persist --json
"$SIENNA_BIN" link meta --no-browser --persist --json
"$SIENNA_BIN" link google --no-browser --persist --json
```

Show only the returned `verification_url`. After the user completes the browser step, run the matching command once with `--resume --json`. If it remains pending, ask the user to finish the browser step and resume again.

## Read data

Use `ask` as the default read command. Include the complete question, providers, date range, comparisons, and requested breakdowns in one call:

```sh
"$SIENNA_BIN" ask "<complete data question>" --json
```

Interpret the returned evidence in Codex. When the result asks for input, present its question to the user and then run the exact returned answer command. When it provides a continuation command, run that exact command if more data is needed.

## Guard changes

Before a command that creates, modifies, publishes, pauses, resumes, cancels, disconnects, or deletes anything:

1. State the exact target and intended change.
2. Run the command with `--dry-run` when available.
3. Obtain explicit user confirmation.
4. Execute only the confirmed command and report its result.

Never reuse confirmation from an unrelated earlier action.
