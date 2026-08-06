# Hosted MCP usage contract

This file describes the inputs and outputs of a Hosted AI connection offered in
the Sienna app. Use the local Sienna CLI for local Plugin work and only the tools
below for Hosted work. Never interchange a local CLI request ID with a Hosted
`job_ref`.

## Connection inputs

- URL: `https://mcp.sienna.work/mcp`
- OAuth permissions: `sienna.analytics.read`, `sienna.jobs.read`, and
  `sienna.creative.read`
- Cancellation may additionally require `sienna.jobs.write`.
- Tools: `sienna_ask`, `sienna_job_status`, `sienna_job_continue`,
  `sienna_job_cancel`, and `sienna_read`

Describe only host connections currently offered in the Sienna app. Do not
claim public support or an installation path for a host that is not offered.

## Requests and results

`sienna_ask` accepts a complete question and optional `crew`. A Research request
may also send `research_depth=quick|standard|deep`; omission means `standard`.
Valid crew values are `performance`, `measurement`, `creative`, and `research`.
`strategy` is unavailable.

Success uses `{ok:true,data:{...}}`. Preserve an error's `kind`, `retryable`,
`retry_after_ms`, `message`, and `recovery`. If `insufficient_scope` is returned,
explain the requested additional permission to the user. Never request or show a
provider response body or credential.

Every completed or partial Ask result includes a user-facing `answer` with
`schema_version=ask-answer-v1`, matching status, grounded claims and actions,
crew, and answer-policy provenance. Ordinary results may also include raw
evidence, `requested_crew`, `resolved_crew`, `routing_source`, and
`catalog_version`. A missing, malformed, or ungrounded answer is a failed
result even when evidence is present. Pass the exact returned `job_ref` to
status, continue, or cancel, and do not send another crew or depth on those
follow-up calls.

A completed Research result includes the grounded `answer` and may include
exact or lower-bound totals,
advertiser inventories, count completeness, coverage scopes, and representative
ads. Never present `totals.count_relation=at_least` as exact. When unresolved candidates
remain, preserve `identity_coverage.complete=false`,
`totals.count_complete=false`, and every coverage warning. Report identity
errors with their returned `kind`, `stage=identity_resolution`, `reason`,
`identity_coverage`, `evidence_impact`, and `recovery`.
Never interpret `creative_center_top_ads` as all TikTok ads or as performance
data.

`sienna_job_cancel` changes job state. Preview with `dry_run=true`, show the
target to the user, and execute only after explicit confirmation. Run status,
continue, and cancel through the same Hosted connection that created the job.
If the connection differs, restore the Hosted connection that created the job
and retry the lifecycle command with the same `job_ref`. Do not replace status,
continue, or cancel with a new Ask. If the original connection cannot be
restored, report that cancellation failed and the job may continue running.

## Unsupported work

- Hosted MCP has no `sienna_job_answer`. If an Ask returns `needs_input`, do not
  guess or use its `job_ref` in the CLI. Start the same question as a new local
  `sienna ask query`, present its question, and run its exact `answer_command`.
- Hosted MCP has no Rooms or history tools. Use the corresponding local CLI
  commands when Rooms, Ask history, or provider history are required.
- Publishing, editing, deletion, and provider connect/disconnect are unsupported.
  Do not route those requests through another Hosted tool.
