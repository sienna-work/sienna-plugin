# CLI Contract

## Output

- Typed commands return `{"ok":true,"data":...}` or `{"ok":false,"error":{"kind","message","recovery"}}` with `--json`.
- `meta get`, `google query`, and a completed natural-language `ask` intentionally return upstream JSON without the Sienna success envelope.
- `ask --json` returns a typed envelope only when it needs user input; its `data` includes `status`, `question`, `answer_contract`, and the exact `answer_command`.
- Exit codes are stable: `0` success, `2` validation, `3` not found, `4` authentication, `5` network, `1` internal.
- stdout contains results. stderr contains diagnostics and optional update hints.
- Never echo access tokens, refresh tokens, session tokens, appsecret proofs, poll secrets, or secret-bearing URLs.

## Discovery

Use `sienna <command> --help` before inventing flags. Start with:

```sh
sienna auth status --json
sienna account list --json
sienna google accounts --json
sienna ask "최근 7일 메타 광고 성과를 보여줘" --json
```

Use IDs returned by discovery calls. Do not guess ad account, customer, campaign, ad set, ad, or creative IDs.

## Recovery

- Authentication error: follow the JSON `recovery` field and run `auth status` before starting a new link.
- Unknown command or missing flag: verify `sienna --version`; with user approval, run `sienna update` on writable host installations.
- Network error: retry once only when the operation is read-only, then use `network.md` to identify the blocked domain.
- Natural-language `needs_input`: ask the user the returned question, then run `sienna answer "<exact answer>" --json` in a new invocation. Do not invent the answer.
- Natural-language backend failure: use the reported path with direct `sienna meta get`, or construct the direct read-only call from the user's request.
- Pagination: pass the provider cursor or page token explicitly. Sienna does not silently fetch every page.

## Safety

- Do not pass `access_token` or `appsecret_proof` through Meta `--param` values.
- Do not put credentials in argv, environment variables, files, prompts, or reports. Existing environment overrides are only for user-controlled CI.
- Use `--dry-run` and explicit confirmation for mutations.
