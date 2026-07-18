# Hosted MCP boundary

This Codex Skill is a local CLI integration. Hosted AI tools use the separate read-only
Streamable HTTP endpoint `https://mcp.sienna.work/mcp` with Sienna OAuth and the
`sienna.analytics.read`, `sienna.jobs.read`, and `sienna.creative.read` scopes.

The remote endpoint exposes only `sienna_ask`, `sienna_job_status`,
`sienna_job_continue`, and `sienna_read`. Hosted jobs cannot be resumed through local CLI
job commands, and revoking one Hosted connection does not log the CLI out. The endpoint
does not serve Skill or agent files. Host packages carry their own instructions and only
reference the remote URL; Notion Custom Agents do not install this Plugin package.

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

Job status and continuation require the same active connection ID that created the job.
The Sienna app lists each same-host connection generation independently and can revoke every
active or reauthentication-required connection without logging the local CLI out.

ChatGPT remains internal-review-only until the public Plugin is approved. Notion remains an
allowlisted weekly-report pilot bound to an approved connector user and one Custom Agent; its
app CTA appears only when the current user's pilot eligibility is satisfied. Do not present
either as generally available based only on the presence of this local Skill.
