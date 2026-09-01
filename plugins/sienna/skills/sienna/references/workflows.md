# Advertising Workflows

## Choose one action

- Account discovery: `sienna ads accounts list|ask`
- Paid-ad metrics: `sienna ads metrics query|ask`
- Analyzed owned creatives: `sienna ads creative list|show|search`
- Public market, brand, and competitor research: `sienna research ask`
- Cross-surface history and lifecycle: `sienna jobs ...`
- Organic account, post, and metrics work: `sienna social ...`

## Accounts

```sh
sienna ads accounts list --json
sienna ads accounts list --platform meta --platform google --json
sienna ads accounts ask "성과 조회에 쓸 계정을 찾아줘" --json
```

Omit platforms to inspect Meta, Google Ads, and Adjust together. A filtered
request attempts only the specified platforms. Preserve platform-specific
successes and errors independently.

## Metrics

Use a structured query only when the platform and native arguments are known:

```sh
sienna ads metrics query --platform meta --account-id act_123 \
  --arguments-json '{"params":{"fields":"ad_id,spend,impressions","date_preset":"last_7d"}}' --json

sienna ads metrics query --platform google --account-id 1234567890 \
  --arguments-json '{"query":"SELECT campaign.id, metrics.clicks FROM campaign WHERE segments.date DURING LAST_7_DAYS"}' --json

sienna ads metrics query --platform adjust --account-name "Example App" \
  --arguments-json '{"dimensions":"app","metrics":"installs","date_period":"-7d:-1d","filters":{}}' --json
```

Use natural language for interpretation or multiple platforms:

```sh
sienna ads metrics ask "지난 7일 Meta와 Google의 지출과 전환을 비교해줘" \
  --platform meta --platform google --json
```

Do not mix arguments from different platforms. Never send provider credentials,
full URLs, HTTP methods, mutations, or non-SELECT GAQL.

## Creative analysis

```sh
sienna ads creative list --account act_123 --json
sienna ads creative show --ad 456 --json
sienna ads creative search "초반 CTA가 있는 제품 데모" --limit 5 --json
```

Join creative observations to live metrics by stable ad ID. Describe patterns
as observations, not causes, and preserve sample size and analysis warnings.

## Research

```sh
sienna research ask "이 시장의 주요 브랜드와 광고 메시지를 정리해줘" \
  --scope market --scope brand --depth standard --json
sienna research ask "A사와 B사의 현재 공개 광고를 빠르게 비교해줘" \
  --scope competitor --depth quick --json
```

Scope is optional and repeatable. Keep market context, brand observations, and
competitor inventories separate in the result. Preserve exact versus lower-bound
counts, coverage gaps, source URLs, live status, and analyzed sample counts.
Never infer spend, impressions, clicks, conversions, revenue, CTR, or ROAS from
public-ad presence.

## Watchlist

```sh
sienna research watch preflight "https://example-competitor.com" --json
sienna research watch add --preflight-id <PREFLIGHT_ID> \
  --candidate-token <CANDIDATE_TOKEN> --display-name "Example Co" --execute --json
sienna research watch show <WATCH_ID> --current-results --json
sienna research watch runs <WATCH_ID> --json
```

Preflight a URL, show the returned candidates, obtain explicit confirmation,
then `add --execute` the chosen candidate. `pause`, `resume`, and `delete`
follow the same preview-then-`--execute` pattern. `show --current-results`
returns the stored latest ad inventory and creative analysis without starting
new collection. `runs` is an execution status/summary list only — never
present it as a diff or change history.

## Job handling

Action output always includes a Job ID. When CLI waits, it still uses that same
Job. For a detached or interrupted action:

```sh
sienna jobs status <JOB_ID> --json
sienna jobs wait <JOB_ID> --json
```

If status is `needs_input`, present its question and choices, then:

```sh
sienna jobs answer <JOB_ID> "<exact user answer>" --json
```

There is no continuation command. An `ask-report-v1` terminal returns a Markdown
report by default. A terminal `partial` report is usable: show the report plus
target errors, recovery, and warnings. Use `sienna jobs data <JOB_ID>` when
bounded canonical results and collection limits are also needed. It omits the
report and returns only cited results. New reports link uppercase
`DATA-XXXXXXXX` `citation_id` to the report footnote; legacy saved reports use
their UUID or target/source ID. Empty rows remain a valid result.

Lifecycle mutations preview by default:

```sh
sienna jobs cancel <JOB_ID> --json
sienna jobs cancel <JOB_ID> --execute --json
sienna jobs delete <JOB_ID> --json
sienna jobs delete <JOB_ID> --execute --json
sienna jobs list --trashed --json
sienna jobs restore <JOB_ID> --json
sienna jobs purge <JOB_ID> --json
```

Cancel active work before deletion. Explain that purge is irreversible and
execute it only after explicit confirmation.

## Social

Social keeps its own command-specific lifecycle. Use the list/show commands
documented by its help before mutating an opaque ID. For social
create/cancel/retry/disconnect, perform the command's dry-run first and obtain
explicit confirmation. External social posts are read-only.

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

Owned posts discovered for connected accounts outside Sienna are included with `"source": "external"`
(filter lists and metrics with `--source sienna|external|all`). Recent external
posts from connected accounts can be listed, shown, and joined with metrics.
Owned-content search and profiling remain Instagram-only. Arbitrary public URLs
and competitor-account posts remain
unsupported. External posts are read-only: `cancel`, `retry`, and their dry-runs
reject them with a typed `read_only` error — do not retry those calls.

If metrics fail with a `validation` error mentioning the analytics add-on, the
provider plan does not include analytics. Report it to the operator; account
management and publishing keep working.

## X Comment Observation And Reply

These commands require Sienna 0.17.11 or newer. Connecting an X account starts
comment collection automatically. Inspect its read-only state with:

```sh
sienna social comment status --account <X_ACCOUNT_ID> --json
```

Status returns `collection_status=collecting|degraded`, collection start time,
tracked post scope, cost status, and warnings without changing anything.
Collection can create usage costs. Preserve every warning. To end collection,
disconnect the X account using the separately confirmed account-disconnect
flow; there is no collection-only start or stop command.

List only comments observed after the requested time:

```sh
sienna social comment list --account <X_ACCOUNT_ID> \
  --since 2026-08-17T00:00:00+09:00 --limit 50 --json
sienna social comment list --account <X_ACCOUNT_ID> \
  --since 2026-08-17T00:00:00+09:00 --post <POST_ID> \
  --cursor <NEXT_CURSOR> --json
```

Preserve `coverage.mode=observed`, `coverage.requested_since`,
`coverage.collection_started_at`, `coverage.retained_from`, collection status,
scope, warnings, `comment_id`, `post_id`, `parent_comment_id`, content, author
name and username, profile image URL, original link, timestamps, and
`source_platform=x`. Empty results
mean “no comments were observed,” never “X has no comments.”

Preview one reply with the exact stored comment ID and exact text:

```sh
sienna social comment reply <COMMENT_ID> --account <X_ACCOUNT_ID> \
  --content "사용자가 직접 쓴 답변" --content-origin user --dry-run --json
```

Show the dry-run target, exact content, origin, and policy status, then obtain
explicit confirmation before removing `--dry-run`. Agent-generated or
materially rewritten text must use `--content-origin ai`; its actual posting is
blocked in the first release even after approval. Do not relabel it or use a
different post command to bypass the block. A succeeded or unknown attempt
locks that source interaction. For `unknown`, do not retry: ask the user to
inspect the X thread manually.

## Mutations

When a write command exists, run its `--dry-run` form first. Present the account, object IDs, and changes, then wait for explicit confirmation before the final command.
