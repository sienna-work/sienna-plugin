# CLI Contract

## Output

- Typed commands return `{"ok":true,"data":...}` or `{"ok":false,"error":{"kind","message","recovery"}}` with `--json`.
- Direct `sienna ads meta get`, `sienna ads google query`, and `sienna ads adjust report` reads return upstream JSON without the Sienna success envelope.
- `ask --json` waits without a CLI-wide deadline and emits exactly one stdout JSON document at terminal. Completed or partial `data` contains `status`, raw `evidence`, `warnings`, `timing`, and typed `crew` provenance and never contains a synthesized `answer`; `needs_input` contains `request_id`, `question`, `answer_contract`, the exact `answer_command`, and the inherited crew provenance after resolution.
- Exit codes are stable: `0` success, `2` validation, `3` not found, `4` authentication, `5` network, `1` internal.
- stdout contains results. stderr contains diagnostics and optional update hints.
- Never echo access tokens, refresh tokens, session tokens, appsecret proofs, poll secrets, or secret-bearing URLs.
- `ads history list --json` returns one typed Sienna envelope containing body-free summaries, retention/quota metadata, and an opaque `next_cursor`. `ads history show <HISTORY_ID> --json` is the only history command that returns the full canonical request and redacted provider result.
- `ask history list --json` returns Ask terminal summaries (prompt preview only), including nullable `requested_crew`, `resolved_crew`, `routing_source`, and `catalog_version`. `ask history show <REQUEST_ID> --json` returns the same provenance with Ask meta plus linked provider query history summaries. Leave legacy nulls unknown rather than inferring them from the prompt.

## Provider History

```sh
sienna ads history list --provider meta --limit 20 --json
sienna ads history list --executor-caller agent --cursor <OPAQUE_CURSOR> --json
sienna ads history show <HISTORY_ID> --json
```

History supports `provider`, `operation`, `invocation-path`, `executor-caller`,
and canonical provider `account` filters. Default output is bounded; lists never
contain request or response bodies. Default maximum retention is 30 days and the
configured maximum is 90 days, but tenant record/byte quotas can evict completed
rows earlier. Provider history is secret-free and is not the 24-hour
conversation trace: it contains no prompt, confirmation Q&A, planner message,
or final natural-language answer. Hosted MCP exposes no history retrieval tool.

## Ask History

```sh
sienna ask history list --status completed --limit 20 --json
sienna ask history show <REQUEST_ID> --json
```

Ask history stores terminal Ask meta only. Child provider calls are linked by
`request_id`/`root_request_id` at read time. Lists omit full prompts and child
bodies. Retention defaults match provider history but use a separate quota.
Hosted MCP exposes no Ask history tool.

## Discovery

Use `sienna <command> --help` before inventing flags. Start with:

```sh
sienna auth status --json
sienna social account list --json
sienna social post list --json
sienna ask query "접근 가능한 계정과 최근 7일 Meta·Google 광고 성과를 보여줘" --json
sienna ask query "광고 소재별 시각 패턴과 성과를 비교해줘" --crew creative --json
```

Use IDs returned by discovery calls. Do not guess ad account, customer,
campaign, ad set, ad, creative, social account, or social post IDs. Social IDs
are opaque and can change after reconnection or a backend migration.

## Recovery

- Authentication error: follow the JSON `recovery` field and run `auth status` before starting a new link.
- Unknown command or missing flag: verify `sienna --version`; with user approval, run `sienna setup update` on writable host installations.
- Network error: retry once only when the operation is read-only, then use `network.md` to identify the blocked domain.
- Interrupted natural-language wait: the server job continues. Resume the stderr request id with `sienna ask wait <request_id> --json`, or omit the id to recover the latest safe job for the current user and environment.
- Detached natural-language request: `ask`, `answer`, and `continue` accept `--detach`, but use it only when a non-terminal success was explicitly requested. Follow `data.wait_command` to retrieve the terminal result.
- Cancellation: inspect with `sienna ask cancel <request_id> --dry-run --json`; cancellation is explicit and cooperative and may allow an in-flight provider read to finish.
- Natural-language `needs_input`: ask the user the returned question, then run the returned `sienna ask answer <request_id> "<exact answer>" --json`. Do not invent the answer.
- Natural-language `partial`: use only returned evidence and identify warnings. For `complete:false`, narrow the query or run the returned `sienna ask continue <request_id> --json`; if the provider cursor expired, start a narrower `ask`.
- Natural-language backend failure: retry once with a narrower question, then use a direct structured read (`sienna ads meta get`, `sienna ads google query`, `sienna ads adjust report`, or `sienna ads creative` commands) when the path is known.
- Crew validation: use only `performance`, `measurement`, or `creative` after `--crew`; `strategy` is disabled. `crew_unknown`, `crew_disabled`, and `crew_capability_mismatch` are validation failures; `crew_profile_unavailable` requires a new Ask. Never add crew to `answer`, `continue`, `wait`, or `cancel`.
- Ask pagination: the executor follows provider cursors automatically within page, byte, and timeout budgets. It returns all fetched rows plus `pages`, `complete`, and `next_cursor`; continuation is server-managed.
- Social account auth error: refresh with `sienna social account list`; if
  `needs_reconnect` is true, start `sienna social account connect instagram`.
- Social post status: poll with `sienna social post show <POST_ID>` or `social
  post list`; scheduled processing continues after the CLI exits.
- Social metrics `validation` error naming the analytics add-on: the provider
  plan lacks analytics. Report it to the operator instead of retrying; other
  social commands keep working.
- Social `not_found` on cancel/retry for a post seen in `post metrics`: the
  post is external (published outside Sienna) and is metrics-only. Do not
  retry the mutation.

## Safety

- Do not pass `access_token` or `appsecret_proof` through Meta `--param` values.
- Do not put credentials in argv, environment variables, files, prompts, or reports. Existing environment overrides are only for user-controlled CI.
- Use `--dry-run` and explicit confirmation for mutations.
- Never print or persist provider keys, backend Profile IDs, callback state,
  presigned upload URLs, or query signatures. A displayed Sienna verification
  URL is only for the user currently completing that short-lived flow.
