# CLI Contract

## Output

- Typed commands return `{"ok":true,"data":...}` or `{"ok":false,"error":{"kind","message","recovery"}}` with `--json`.
- Deprecated direct `meta get`, `google query`, and `adjust report` reads keep returning upstream JSON without the Sienna success envelope during migration.
- `ask --json` always returns a typed envelope. Completed or partial `data` contains `status`, `answer`, `evidence`, `warnings`, and `timing`; `needs_input` contains `question`, `answer_contract`, and the exact `answer_command`.
- Exit codes are stable: `0` success, `2` validation, `3` not found, `4` authentication, `5` network, `1` internal.
- stdout contains results. stderr contains diagnostics and optional update hints.
- Never echo access tokens, refresh tokens, session tokens, appsecret proofs, poll secrets, or secret-bearing URLs.

## Discovery

Use `sienna <command> --help` before inventing flags. Start with:

```sh
sienna auth status --json
sienna social account list --json
sienna social post list --json
sienna ask "접근 가능한 계정과 최근 7일 Meta·Google 광고 성과를 보여줘" --json
```

Use IDs returned by discovery calls. Do not guess ad account, customer,
campaign, ad set, ad, creative, social account, or social post IDs. Social IDs
are opaque and can change after reconnection or a backend migration.

## Recovery

- Authentication error: follow the JSON `recovery` field and run `auth status` before starting a new link.
- Unknown command or missing flag: verify `sienna --version`; with user approval, run `sienna update` on writable host installations.
- Network error: retry once only when the operation is read-only, then use `network.md` to identify the blocked domain.
- Natural-language `needs_input`: ask the user the returned question, then run `sienna answer "<exact answer>" --json` in a new invocation. Do not invent the answer.
- Natural-language `partial`: use only returned evidence, identify warnings and retry the missing scope.
- Natural-language backend failure: retry once with a narrower question, then use a deprecated direct read only for outage diagnosis or existing-script migration.
- Pagination: pass the provider cursor or page token explicitly. Sienna does not silently fetch every page.
- Social account auth error: refresh with `sienna social account list`; if
  `needs_reconnect` is true, start `sienna social account connect instagram`.
- Social post status: poll with `sienna social post get <POST_ID>` or `social
  post list`; scheduled processing continues after the CLI exits.

## Safety

- Do not pass `access_token` or `appsecret_proof` through Meta `--param` values.
- Do not put credentials in argv, environment variables, files, prompts, or reports. Existing environment overrides are only for user-controlled CI.
- Use `--dry-run` and explicit confirmation for mutations.
- Never print or persist provider keys, backend Profile IDs, callback state,
  presigned upload URLs, or query signatures. A displayed Sienna verification
  URL is only for the user currently completing that short-lived flow.
