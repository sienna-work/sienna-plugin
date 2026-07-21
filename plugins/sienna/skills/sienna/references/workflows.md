# Advertising Workflows

Choose the surface by domain:

- `sienna ask query` — open-ended or multi-provider/multi-domain questions
- `sienna ads …` — known paid-ads structured reads (Meta, Google, Adjust, creative analysis)
- `sienna social …` — organic Instagram connect/post/metrics

## Natural-Language Ask

For multi-provider or open-ended questions, send the complete question once so independent provider reads can run in parallel:

```sh
sienna ask query "최근 7일 Meta와 Google Ads 캠페인 성과를 비교해줘" --json
sienna ask query "지난 30일 ROAS 상위 Meta 광고의 공통 Creative 특징을 알려줘" --crew creative --json
sienna ask query "Meta와 Adjust 전환 집계 차이를 점검해줘" --crew measurement --json
# If status is needs_input, ask the returned question and run answer_command, e.g.:
sienna ask answer <request_id> "<exact user answer>" --json
# If the CLI was interrupted, resume the same server job without starting over:
sienna ask wait <request_id> --json
```

Omit `--crew` for server auto selection. Use explicit `performance` for broad delivery/efficiency reads, `measurement` for attribution or tracking discrepancies, and `creative` for analyzed feature/pattern evidence. Explicit selection fixes the root profile; `strategy` is disabled. Crew is a profile inside one Query Agent, not a request for the host harness to create subagents.

Let `ask`, `answer`, and `continue` wait for terminal evidence even when they take several minutes. Use `--detach` only for an explicitly requested background handoff. Interpret `data.evidence` directly; `ask` does not synthesize an `answer`. Read `data.crew` as bounded provenance, and do not send a new crew on `answer` or `continue`; both inherit the root. Use `data.gaps` for missing optional or failed provider coverage; `warnings` stay for assumptions and date-range caveats only. When `continue_command` is present, run it exactly for pagination. When `status=completed` with non-empty `gaps`, analyze the returned evidence first and follow each gap recovery only if that coverage is still required. When `status=partial` without `continue_command`, use the available evidence first and follow each required gap's direct-read recovery only when the missing coverage is needed. Do not use `sienna ask answer` for free-form follow-ups or start another broad `sienna ask query` merely to repair a known provider path.

## Structured Direct Reads

Use the commands below when the provider path is already known, or for pagination or large raw diagnostics. They bypass AgentCore but still use the same authenticated Query API relay and server-side credentials. Query API or broker outages have no local provider fallback.

### Meta Ads

```sh
sienna ads meta accounts --json
sienna ads meta get /me/adaccounts --param fields=id,name --json
sienna ads meta get /act_<ID>/insights \
  --param fields=ad_id,ad_name,spend,impressions,clicks,actions,purchase_roas \
  --param level=ad --param date_preset=last_30d --json
```

`sienna ads meta get` is read-only and does not auto-follow `paging`. Never provide `access_token` or `appsecret_proof` as parameters.

### Google Ads

```sh
sienna ads google accounts --json
sienna ads google campaigns --customer <CUSTOMER_ID> --json
sienna ads google query \
  "SELECT campaign.id, campaign.name, metrics.impressions, metrics.clicks, metrics.cost_micros FROM campaign WHERE segments.date DURING LAST_7_DAYS" \
  --customer <CUSTOMER_ID> --json
```

Discover the customer ID first. Add `segments.date` for daily rows and `--login-customer-id` for an MCC when required. `cost_micros` is one millionth of the account currency. Pass `nextPageToken` back with `--page-token` for another page.

### Adjust

```sh
sienna ads adjust events --tokens-mapping --json
sienna ads adjust report \
  --dimensions app \
  --metrics installs,<EVENT_ID>_events \
  --date-period -7d:-1d --json
```

For a named event, resolve the exact event with `sienna ads adjust events`; add `_events` to the returned event id before using it as a report metric. Never use an SDK token or bare event id as a metric. Adjust access is read-only. Use the broker browser flow for normal linking; never ask the user to paste an Adjust token into chat.

### Creative Performance Join

Join live performance to analyzed features by ad ID. Either ask Sienna once, or compose the join with direct commands:

1. Query Meta insights at `level=ad` and rank ads using the requested business metric. Preserve `ad_id`.
2. Fetch analyzed features with `sienna ads creative show --ad <AD_ID> --json` for representative top and comparison ads.
3. Join analysis records to performance rows by ad ID. Use the returned ad, ad set, campaign, and account join identifiers to validate scope.
4. Compare features across groups and distinguish observed patterns from causal claims.

Useful commands:

```sh
sienna ads creative list --account act_<ID> --json
sienna ads creative show --ad <AD_ID> --json
sienna ads creative search "bright product demo, early CTA" --limit 5 --json
```

A 404 may mean the creative is not analyzed yet or is outside the authenticated account. Use `sienna ads creative list` to inspect `done`, `pending`, `failed`, or `excluded` state.

## Instagram Social Publishing

Connect and discover the current opaque account ID:

```sh
sienna social account connect instagram --no-browser --persist --json
sienna social account connect instagram --resume --json
sienna social account list --json
sienna social account status <SOCIAL_ACCOUNT_ID> --json
```

Run dry-run first and present the normalized target, mode, schedule, content
summary, and media metadata for confirmation:

```sh
sienna social post create --account <SOCIAL_ACCOUNT_ID> \
  --content "출시 소식" --media ./launch.jpg --draft --dry-run --json

sienna social post create --account <SOCIAL_ACCOUNT_ID> \
  --content "오늘 공개합니다" --publish-now --dry-run --json

sienna social post create --account <SOCIAL_ACCOUNT_ID> \
  --content "예약 게시" --media ./scheduled.jpg \
  --scheduled-for 2026-07-15T09:00:00+09:00 \
  --timezone Asia/Seoul --dry-run --json
```

Repeat `--account` for multiple owned Instagram targets. Local media scheduling
is limited to six days because the temporary upload expires; text-only posts or
long-lived public `--media-url` values can use the normal provider range. Never
show a presigned URL or its query signature.

After explicit confirmation, remove `--dry-run`. Poll current state and guard
follow-up mutations the same way:

```sh
sienna social post list --json
sienna social post show <POST_ID> --json
sienna social post cancel <POST_ID> --dry-run --json
sienna social post retry <POST_ID> --dry-run --json
sienna social account disconnect <SOCIAL_ACCOUNT_ID> --dry-run --json
```

If an account needs reconnection, start the Instagram connect flow and then
rediscover all opaque IDs. A future direct-platform backend may also require a
reconnect and may replace account/post IDs.

## Instagram Social Metrics

Read-only performance metrics for connected accounts and their posts. No
`--dry-run` exists because nothing mutates and nothing is stored:

```sh
sienna social post metrics --sort engagement --order desc --limit 10 --json
sienna social post metrics --account <SOCIAL_ACCOUNT_ID> \
  --from 2026-06-01 --to 2026-07-01 --json
sienna social post metrics <POST_ID> --json
sienna social account metrics <SOCIAL_ACCOUNT_ID> --json
```

Metrics are cumulative provider snapshots with a per-post `last_updated` time;
there is no per-day series, so compare posts against each other or re-poll for
fresh totals. The list range is limited to 366 days and pages of 1–100 items.

Posts published outside Sienna are included with `"source": "external"`
(filter with `--source sienna|external|all`). External posts are metrics-only:
`post get`, `cancel`, and `retry` reject them with a `not_found` error whose
recovery hint explains the read-only contract — do not retry those calls.

If metrics fail with a `validation` error mentioning the analytics add-on, the
provider plan does not include analytics. Report it to the operator; account
management and publishing keep working.

## Mutations

When a write command exists, run its `--dry-run` form first. Present the account, object IDs, and changes, then wait for explicit confirmation before the final command.
