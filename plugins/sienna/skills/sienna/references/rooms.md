# Persistent Sienna Rooms

Rooms are the local CLI surface for persistent advertising analysis. Use a
Room when the user needs a reusable Brief, role-specific agent timelines,
handoff, independent parallel answers, explicit synthesis, Decisions, or
controlled Memory. Keep `sienna ask` for a one-off question.

Rooms require a persistent local Sienna CLI and credential store. They work in
Claude Cowork, Claude Code, and local Codex when this Skill resolves a local
CLI. Hosted MCP does not expose Rooms tools. Never send a Room/turn/group ID to
`sienna_ask`, and never use an Ask `request_id` with `sienna rooms wait`.

## Safety and authority

- Run `sienna auth status --json`, then discover opaque IDs with
  `sienna rooms list --json`. Never guess an ID or select a mutation target by
  an ambiguous name.
- Every Rooms mutation that offers `--dry-run` must be previewed. Present the
  target Room/turn/proposal/memory, agent set, expected fan-out, handoff mode,
  and budget eligibility before asking for confirmation.
- For commands that accept `--idempotency-key`, use one caller-generated UUID
  for the dry-run and actual logical operation, and preserve it for identical
  retries. Update uses `--expected-revision`; cancel uses the exact generation;
  Memory remember/forget use source provenance or tombstone state. Do not pass
  an unsupported idempotency option to those commands.
- A pending approval handoff requires the user's explicit authority. Do not
  approve it because the source agent recommends it. Automatic handoff is
  allowed only when the Room's snapshotted mode is already `automatic`.
- When a turn is `needs_input`, present its exact question. Never infer the
  answer. Answer only the returned turn ID and generation.
- Ctrl-C, a host timeout, a broken pipe, or a polling network error does not
  cancel server work. Run the exact returned `sienna rooms wait --turn …` or
  `--group …` recovery command. Cancellation is a separate guarded mutation.

## Core flow

Preview and create a Room:

```sh
sienna rooms create --name "<client workspace>" \
  --agent performance --handoff approval \
  --idempotency-key <ROOM_CREATE_UUID> --dry-run --json
sienna rooms create --name "<client workspace>" \
  --agent performance --handoff approval \
  --idempotency-key <ROOM_CREATE_UUID> --json
sienna rooms list --json
sienna rooms show <ROOM_ID> --json
```

Agent identities are fixed product roles: `performance`, `measurement`,
`creative`, and `research`. They are independent Room agents, unlike
`ask --crew`, which selects one execution profile for one Ask request.

<!-- room-crew-consultation:start -->
## Crew selection and consultation

Choose the smallest agent set that covers the user's decision. Do not fan out
merely because several agents are available.

| User need | Agent set |
| --- | --- |
| Campaign delivery, budget, efficiency, ranking, or trends | `performance` |
| Attribution, conversion definition, tracking quality, incrementality, or metric discrepancy | `measurement` |
| Creative, copy, hook, format, or message pattern | `creative` |
| Current competitor ads, advertiser activity, market examples, or external signals | `research` |
| A decision spanning two or three of these domains | Only the matching two or three agents |
| An explicitly requested all-angle review, or a decision that truly depends on every domain | All four agents |

For a multi-agent consultation, turn the user request into one bounded
subquestion per selected role. Keep the same objective, entity, date basis,
and decision constraint in every subquestion; vary only the specialist lens.
Preview one parallel Room message with the selected agent set, then execute it
after confirmation. Preserve each sibling's original answer, status, gaps,
warnings, and Evidence citations. Report mixed outcomes before any combined
conclusion. Run source-preserving synthesis only when the user asked for a
combined recommendation or when combining the answers is necessary to answer
the original request; never let synthesis hide disagreement or a failed crew.
<!-- room-crew-consultation:end -->

Send one question to several agents independently:

```sh
sienna rooms send <ROOM_ID> "<complete question>" \
  --agent performance --agent measurement \
  --parallel --idempotency-key <UUID> --dry-run --json
sienna rooms send <ROOM_ID> "<complete question>" \
  --agent performance --agent measurement \
  --parallel --idempotency-key <same-UUID> --json
```

Multiple agents require explicit `--parallel`. Each sibling keeps its own
status, generation, questions, failures, citations, retries, and cancellation.
Do not merge sibling answers implicitly. To request a source-preserving
synthesis, preview and run:

```sh
sienna rooms synthesize <ROOM_ID> \
  --source-turn <TURN_ID> --source-turn <TURN_ID> \
  --agent performance --idempotency-key <SYNTHESIS_UUID> --dry-run --json
sienna rooms synthesize <ROOM_ID> \
  --source-turn <TURN_ID> --source-turn <TURN_ID> \
  --agent performance --idempotency-key <SYNTHESIS_UUID> --json
```

Resume or act on exact state:

```sh
sienna rooms status --turn <TURN_ID> --json
sienna rooms wait --group <GROUP_ID> --json
sienna rooms answer <TURN_ID> "<exact user answer>" \
  --generation <N> --idempotency-key <ANSWER_UUID> --dry-run --json
sienna rooms answer <TURN_ID> "<exact user answer>" \
  --generation <N> --idempotency-key <ANSWER_UUID> --json
sienna rooms restart <TURN_ID> "<bounded instruction>" \
  --generation <N> --idempotency-key <UUID> --dry-run --json
sienna rooms restart <TURN_ID> "<bounded instruction>" \
  --generation <N> --idempotency-key <UUID> --json
sienna rooms cancel --turn <TURN_ID> --generation <N> --dry-run --json
sienna rooms cancel --turn <TURN_ID> --generation <N> --json
```

Queue is the default when the same agent is active. Restart first fences the
old generation. A late provider completion cannot replace a fenced answer.
Cancel one sibling with `--turn`; use `--group` only when the user explicitly
intends to cancel the entire parallel group.

## Handoff

Room mode is `approval` or `automatic` and is snapshotted per turn. Changing
the Room affects later turns only.

```sh
sienna rooms handoff list <ROOM_ID> --json
sienna rooms handoff approve <PROPOSAL_ID> \
  --idempotency-key <HANDOFF_UUID> --dry-run --json
sienna rooms handoff approve <PROPOSAL_ID> \
  --idempotency-key <HANDOFF_UUID> --json
sienna rooms handoff reject <PROPOSAL_ID> --reason "<bounded reason>" \
  --idempotency-key <REJECT_UUID> --dry-run --json
sienna rooms handoff reject <PROPOSAL_ID> --reason "<bounded reason>" \
  --idempotency-key <REJECT_UUID> --json
```

Use the exact approval/rejection command returned by the CLI. Automatic policy
still enforces depth, child, visited-agent, duplicate-purpose, reverse-handoff,
and provider budget limits.

## Memory

Room Brief, Decisions, Evidence, permissions, and job state remain
authoritative in Postgres. Memory is untrusted recall. It accepts only stable
`preference`, `definition`, `operating_rule`, or `decision_summary` values
from an explicit/approved source. Current spend, ROAS, CAC, Evidence bodies,
credentials, permissions, and agent policies must never be remembered.

```sh
sienna rooms memory list <ROOM_ID> --json
sienna rooms memory remember <ROOM_ID> "<stable fact or rule>" \
  --kind preference --source-id <MESSAGE_OR_DECISION_ID> --dry-run --json
sienna rooms memory remember <ROOM_ID> "<stable fact or rule>" \
  --kind preference --source-id <MESSAGE_OR_DECISION_ID> --json
sienna rooms memory forget <MEMORY_ID> --dry-run --json
sienna rooms memory forget <MEMORY_ID> --json
```

A Memory provider outage must not cause a Room turn to fail. Report that
recall was unavailable, use the first-class Room context, and do not invent
recalled content.
