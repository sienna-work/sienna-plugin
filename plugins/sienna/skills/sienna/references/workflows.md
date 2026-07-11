# Advertising Workflows

## Meta Ads

Optional natural-language convenience path:

```sh
sienna ask "최근 7일 메타 광고 성과를 캠페인별로 보여줘" --json
# If status is needs_input, ask the returned question and then run:
sienna answer "<exact user answer>" --json
```

This path supports read-only Meta GET only. A successful result uses the same raw JSON/report renderer as the equivalent direct command. It may repair a Meta validation error and retry within a small fixed budget, but it must not silently change the account, date range, or reporting level. Use the direct path below when the endpoint is unavailable or the query is already known.

```sh
sienna account list --json
sienna meta get /me/adaccounts --param fields=id,name --json
sienna meta get /act_<ID>/insights \
  --param fields=ad_id,ad_name,spend,impressions,clicks,actions,purchase_roas \
  --param level=ad --param date_preset=last_30d --json
```

`meta get` is read-only and does not auto-follow `paging`. Never provide `access_token` or `appsecret_proof` as parameters.

## Google Ads

```sh
sienna google accounts --json
sienna google campaigns --customer <CUSTOMER_ID> --json
sienna google query \
  "SELECT campaign.id, campaign.name, metrics.impressions, metrics.clicks, metrics.cost_micros FROM campaign WHERE segments.date DURING LAST_7_DAYS" \
  --customer <CUSTOMER_ID> --json
```

Discover the customer ID first. Add `segments.date` for daily rows and `--login-customer-id` for an MCC when required. `cost_micros` is one millionth of the account currency. Pass `nextPageToken` back with `--page-token` for another page.

## Adjust

```sh
sienna adjust report \
  --dimensions app \
  --metrics installs,revenue \
  --date-period -7d:-1d --json
```

Adjust access is read-only. Use the broker browser flow for normal linking; never ask the user to paste an Adjust token into chat.

## Creative Performance Join

Use this workflow for questions such as "What visual traits do our top-ROAS ads share?"

1. Query Meta insights at `level=ad` and rank ads using the requested business metric. Preserve `ad_id`.
2. Fetch analyzed features with `sienna creative show --ad <AD_ID> --json` for representative top and comparison ads.
3. Join analysis records to performance rows by ad ID. Use the returned ad, ad set, campaign, and account join identifiers to validate scope.
4. Compare features across groups and distinguish observed patterns from causal claims.

Useful commands:

```sh
sienna creative list --account act_<ID> --json
sienna creative show --ad <AD_ID> --json
sienna creative search "bright product demo, early CTA" --limit 5 --json
```

A 404 may mean the creative is not analyzed yet or is outside the authenticated account. Use `creative list` to inspect `done`, `pending`, `failed`, or `excluded` state.

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
sienna social post get <POST_ID> --json
sienna social post cancel <POST_ID> --dry-run --json
sienna social post retry <POST_ID> --dry-run --json
sienna social account disconnect <SOCIAL_ACCOUNT_ID> --dry-run --json
```

If an account needs reconnection, start the Instagram connect flow and then
rediscover all opaque IDs. A future direct-platform backend may also require a
reconnect and may replace account/post IDs.

## Mutations

When a write command exists, run its `--dry-run` form first. Present the account, object IDs, and changes, then wait for explicit confirmation before the final command.
