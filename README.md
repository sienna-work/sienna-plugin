# Sienna Plugin

Public Claude and Codex Plugin metadata and agent instructions for Sienna.

The Plugin contains no Sienna product source, credentials, MCP server, or CLI binary. Claude Cowork downloads the pinned Linux CLI from `get.sienna.work` and verifies it against the release checksum stored in `plugins/sienna/runtime/`. Local Claude Code and Codex installations reuse an existing `sienna` executable or ask before running the official installer.

## Install

Claude Code:

```sh
claude plugin marketplace add sienna-work/sienna-plugin
claude plugin install sienna@sienna
```

Codex:

```sh
codex plugin marketplace add sienna-work/sienna-plugin
codex plugin add sienna@sienna
```

The source of truth is maintained in the private Sienna monorepo. This repository is generated and published after allowlist, secret, symlink, executable, and native Plugin validation.
