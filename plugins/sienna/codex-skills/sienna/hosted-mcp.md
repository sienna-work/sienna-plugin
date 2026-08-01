# Hosted MCP boundary

This Codex Skill is a local CLI integration. Hosted AI tools use the separate read-only
Streamable HTTP endpoint `https://mcp.sienna.work/mcp` with Sienna OAuth and the
`sienna.analytics.read`, `sienna.jobs.read`, and `sienna.creative.read` scopes by
default. Cancellation alone uses an incremental `sienna.jobs.write` scope challenge.

The remote endpoint exposes only `sienna_ask`, `sienna_job_status`,
`sienna_job_continue`, `sienna_job_cancel`, and `sienna_read`. Hosted jobs cannot be resumed through local CLI
job commands, and revoking one Hosted connection does not log the CLI out. The endpoint
does not serve Skill or agent files. Host packages carry their own instructions and only
reference the remote URL; Notion Custom Agents do not install this Plugin package.

Hosted MCP has no Rooms tools. Room creation/listing, messages, turn or group
wait, handoff, synthesis, Decisions, and Memory require the local Sienna CLI
with a persistent credential store. Never use Room/turn/group/proposal/memory
IDs as Hosted `job_ref` or Ask `request_id` values, and never resume a Hosted
job with `sienna rooms wait`.

The remote transport is fully stateless and does not issue or accept arbitrary MCP session
IDs. It supports protocol versions `2025-11-25`, `2025-06-18`, and `2025-03-26`; a client
requesting a newer dated version negotiates the latest supported version. Successful tool
data uses `{ok:true,data:{...}}`. Invalid tool arguments are JSON-RPC `-32602`, while tool
execution failures other than authentication or transport rejection are HTTP 200 `isError`
results. Provider reads require the analytics scope, creative reads require only the
creative scope, and failures expose stable safe kinds/retryability without upstream response
bodies. An `insufficient_scope` response keeps the JSON-RPC `isError` body and includes an
RFC 6750 Bearer challenge with the exact required scope and protected-resource metadata URL,
so the host can start step-up OAuth consent.

`sienna_ask` accepts the same optional top-level `crew` as the CLI and optional
`research_depth=quick|standard|deep` for an initial research request. Omission uses
the server router across `performance`, `measurement`, `creative`, and `research`; explicit
selection fixes the root profile, and `strategy` is disabled. Crew is a profile
inside one Query Agent, not a request for host multi-agent or subagent work.
Ordinary results, `sienna_job_status`, `sienna_job_continue`, and `sienna_job_cancel` preserve raw evidence and
the same typed `requested_crew`, `resolved_crew`, `routing_source`, and `catalog_version`
provenance. Research omission defaults to `standard`;
status and continue inherit the root crew and depth and accept no override.
Period fields are unsupported. A completed Research status defaults to its compact
`result` with exact or lower-bound totals, count completeness, advertiser inventories,
coverage scopes, and representative ads instead of raw evidence and the internal artifact.
Quick observes at most 100 ads per accepted advertiser/source when no cheap exact count
exists and returns at most 10 representative ads overall. Never present
`count_relation=at_least` as exact. Standard/deep retain exact inventory probes.
Never interpret `creative_center_top_ads` as all TikTok ads or infer public-ad performance.
`sienna_job_cancel` cooperatively cancels the root job and linked research child
created by the same connection; use `dry_run=true` to preview.

Hosted MCP does not expose `sienna_job_answer`. If a Hosted Ask returns
`needs_input`, do not guess the answer or try to resume that Hosted request ID
through the CLI. Start the same question as a new local `sienna ask query`, present
its returned question to the user, and resume only with the exact local
`sienna ask answer <request_id> "<answer>" --json` command.

Job status, continuation, and cancellation require the same active connection ID that created the job.
The Sienna app lists each same-host connection generation independently and can revoke every
active or reauthentication-required connection without logging the local CLI out.

ChatGPT remains internal-review-only until the public Plugin is approved. Notion remains an
allowlisted weekly-report pilot bound to an approved connector user and one Custom Agent; its
app CTA appears only when the current user's pilot eligibility is satisfied. Do not present
either as generally available based only on the presence of this local Skill.
