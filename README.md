# Sienna Plugin

Public Claude and Codex Plugin metadata and agent instructions for Sienna.

The Plugin contains no Sienna product source, credentials, or MCP server. Its generated Marketplace package includes checksum-verified Linux amd64 and arm64 CLI runtimes so Claude Cowork works without downloading an executable. Local Claude Code and Codex installations reuse an existing `sienna` executable or ask before running the official installer.

## Install

Claude Cowork:

1. Open Customize, choose Plugins, then Add marketplace.
2. Enter `https://github.com/sienna-work/sienna-plugin`.
3. Install `sienna@sienna`.

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

The source of truth is maintained in the private Sienna monorepo. This repository is generated and published after allowlist, secret, symlink, runtime checksum, package-size, and native Plugin validation.
