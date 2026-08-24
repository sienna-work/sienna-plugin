# Sienna Plugin

Public Claude, Codex, and Cursor Plugin metadata and agent instructions for Sienna.

After installation, follow the bundled Sienna Skill. It documents supported
commands and inputs, the outputs an agent must interpret, confirmation
requirements, and recovery steps.

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

Cursor:

1. Install Sienna from the Cursor Marketplace after its listing is approved.
2. During local review, link `cursor-plugins/sienna` under
   `~/.cursor/plugins/local/sienna`, then reload Cursor.
3. Connect the installed Sienna MCP server and approve Sienna OAuth.

The Cursor package uses `https://mcp.sienna.work/mcp` and does not install a
local runtime or contain API keys, access tokens, or OAuth client secrets.

Use the installed Sienna Skill for supported commands, required confirmation,
structured results, and recovery guidance. Report Plugin problems through the
support link below.

## Product and support

- Product: https://sienna.work
- Support: https://github.com/sienna-work/sienna-plugin/issues
- Privacy: https://auth.sienna.work/privacy
- License: [MIT](LICENSE)
