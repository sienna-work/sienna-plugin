# CLI Contract

## Output

- Typed commands return `{"ok":true,"data":...}` or `{"ok":false,"error":{"kind","message","recovery"}}` with `--json`.
- `auth status --json` includes only the resolved booleans at
  `data.features.creative_content_analysis` and
  `data.features.competitor_research`; leave false features unavailable.
- A gated command returns `kind=feature_not_enabled`, typed `feature`, and
  `recovery.action=contact_support`, or `kind=feature_temporarily_unavailable`
  with `recovery.action=retry_later`. Preserve these fields. Confirm with the
  user before contacting support, then re-run `auth status --json`; retry a
  temporary-unavailability result later.
- Direct `sienna ads meta get`, `sienna ads google query`, and `sienna ads adjust report` reads return upstream JSON without the Sienna success envelope.
- `ask --json` waits for a terminal result and emits exactly one stdout JSON document, except when more user input is required. A `needs_input` response is successful exit `0` but non-terminal; its stdout document contains `status`, `request_id`, `question`, `answer_contract`, and the exact `answer_command`, plus any returned stage, identity coverage, evidence impact, recovery, or crew fields. Present the question and stop. After the user answers, run that exact `answer_command`; do not keep waiting, invent an answer, or start a new Ask.
- Every completed or partial `data` contains a user-facing `answer` with `schema_version=ask-answer-v1`, matching status, grounded claims/actions, crew, and answer-policy provenance. Ordinary responses also contain raw `evidence`, `gaps`, `warnings`, `timing`, and typed crew provenance. Research additionally contains a compact structured `result` (`kind=competitor_ad_research`, exact or lower-bound totals with count completeness, identity coverage, advertisers, coverage warnings, and representative ads). Missing, malformed, or ungrounded answers are failures.
- Exit codes are stable: `0` success, `2` validation, `3` not found, `4` authentication, `5` network, `1` coverage or internal.
- stdout contains results. stderr contains diagnostics and optional update hints.
- Never echo access tokens, refresh tokens, session tokens, appsecret proofs, poll secrets, or secret-bearing URLs.
- `ads history list --json` returns one typed Sienna envelope containing body-free summaries, retention metadata, and an opaque `next_cursor`. `ads history show <HISTORY_ID> --json` returns the redacted canonical request and redacted provider result.
- `ask history list --json` returns Ask terminal summaries (prompt preview only), including nullable crew provenance and research ID/depth/policy. `ask history show <REQUEST_ID> --json` also returns the bounded `answer`, terminal Research metadata, and provider history references. Leave nulls unknown.

## Provider History

```sh
sienna ads history list --provider meta --limit 20 --json
sienna ads history list --executor-caller agent --cursor <OPAQUE_CURSOR> --json
sienna ads history show <HISTORY_ID> --json
```

History supports `provider`, `operation`, `invocation-path`, `executor-caller`,
and canonical provider `account` filters. Default output is bounded; lists never
contain request or response bodies. The default maximum retention is 30 days,
and output metadata may indicate earlier expiration. Hosted MCP exposes no
history retrieval tool.

## Ask History

```sh
sienna ask history list --status completed --limit 20 --json
sienna ask history show <REQUEST_ID> --json
```

Ask history returns terminal Ask metadata and the bounded answer used for
completed or partial output. Lists omit full prompts and provider result bodies.
The default maximum retention is 30 days, and output metadata may indicate
earlier expiration. Hosted MCP exposes no Ask history tool.

## Discovery

Use `sienna <command> --help` before inventing flags. Start with:

```sh
sienna auth status --json
sienna social account list --json
sienna social post list --json
sienna ask query "접근 가능한 계정과 최근 7일 Meta·Google 광고 성과를 보여줘" --json
sienna ask query "광고 소재별 시각 패턴과 성과를 비교해줘" --crew creative --json
sienna ask query "경쟁사들의 현재 공개 광고를 빠르게 조사해줘" --crew research --depth quick --json
```

Use IDs returned by discovery calls. Do not guess ad account, customer,
campaign, ad set, ad, creative, social account, or social post IDs. Social IDs
are opaque; rediscover them after reconnection or a stale-ID error.

## Recovery

- Authentication error: follow the JSON `recovery` field and run `auth status` before starting a new link.
- Unknown command or missing flag: verify `sienna --version`; with user approval, run `sienna setup update` on writable host installations.
- Network error: retry once only when the operation is read-only, then use `network.md` to identify the blocked domain.
- Interrupted natural-language wait: run the exact `sienna ask wait <request_id> --json` command printed on stderr, or omit the id to use the latest recoverable request.
- Detached natural-language request: `ask`, `answer`, and `continue` accept `--detach`, but use it only when a non-terminal success was explicitly requested. Follow `data.wait_command` to retrieve the terminal result.
- Cancellation: inspect with `sienna ask cancel <request_id> --dry-run --json`; cancellation is explicit and cooperative and may allow an in-flight provider read to finish.
- Natural-language `needs_input`: ask the user the returned question, then run the exact returned `answer_command` after the user replies. Do not wait for a terminal result or invent the answer while input is pending.
- Research identity `needs_input`: keep every `resume_context.accepted_advertiser_ids`, add only the selected ID before ` — `, or keep only those accepted IDs for `모두 제외`. Run the exact returned `answer_command`; do not start a new Research Ask or rejudge accepted identities.
- Natural-language `partial`: present the returned answer while preserving its gaps and warnings, and validate its citations against the available evidence/result. For `complete:false`, run the returned exact `sienna ask continue <request_id> --json` before narrowing the query. Narrow only when the continuation cursor has expired or the response explicitly requires broad-query recovery. Quick Research may complete with `count_complete=false`; present `total_ads` as an `at_least` lower bound and use the representative ads. Google public-ad research currently supports quick depth; preserve `source_depth_not_approved` for standard/deep and follow its `--depth quick` recovery rather than retrying the same exact request.
- Missing answer contract: a completed/partial response without a valid grounded `ask-answer-v1` answer is an `answer_composition` failure. Do not promote raw evidence/result to success; use the returned recovery or retry the identical read-only Ask once.
- Research identity dependency failure: preserve the server `kind`, `stage=identity_resolution`, `reason`, `identity_coverage`, `evidence_impact`, and exact `recovery`. Use the stable exit code for its kind and never replace or supplement that recovery with the generic Meta reporting fields/date-range/page-size hint.
- Natural-language request failure: follow the returned recovery. If it names a direct structured read, use that command only when the path is known.
- Crew validation: use only `performance`, `measurement`, `creative`, or `research` after `--crew`; `strategy` is disabled. `--depth quick|standard|deep` is initial-research-only and defaults to `standard`; never add crew or depth to `answer`, `continue`, `wait`, or `cancel`. Period fields are unsupported in v1.
- Ask pagination: read `pages`, `complete`, `next_cursor`, and any returned `continue_command`. Run that exact command when more rows are required.
- Social account auth error: refresh with `sienna social account list`; if
  `needs_reconnect` is true, start `sienna social account connect
  <instagram|x|linkedin> --no-browser --persist --json` with the account's
  returned public `platform`; after browser approval, continue with `sienna
  social account connect <instagram|x|linkedin> --resume --json`. Never pass
  provider-internal `twitter` to the CLI.
- Social post status: poll with `sienna social post show <POST_ID>` or `social
  post list`; scheduled processing continues after the CLI exits.
- Social metrics `validation` error naming the analytics add-on: the provider
  plan lacks analytics. Report it to the operator instead of retrying; other
  social commands keep working.
- Social `read_only` on cancel/retry, including their `--dry-run` forms: the post is external (published outside
  Sienna). It remains available to list/show/metrics/Ask, but the mutation must
  not be retried.

## Safety

- Do not pass `access_token` or `appsecret_proof` through Meta `--param` values.
- Do not put credentials in argv, environment variables, files, prompts, or reports. Existing environment overrides are only for user-controlled CI.
- Use `--dry-run` and explicit confirmation for mutations.
- Display only the returned Sienna verification URL to the user completing the
  flow. Never print or persist another credential, proof, presigned upload URL,
  or query signature.
