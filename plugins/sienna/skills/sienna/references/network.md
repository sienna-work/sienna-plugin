# Cowork Network Requirements

Sienna does not modify network policy. When egress is denied, identify only the required category and ask the user or administrator to allow the exact production domain.

| Category | Domain | Used for |
| --- | --- | --- |
| Authentication | `auth.sienna.work` | Login, provider linking, Google token refresh |
| Creative analysis | `api.sienna.work` | Analyzed creative features and search |
| Meta Ads | `graph.facebook.com` | Meta Graph and Marketing API reads |
| Google Ads | `googleads.googleapis.com` | Google Ads queries |
| Adjust | `automate.adjust.com` | Adjust Report Service reads |
| Host CLI install/update | `get.sienna.work` | Claude Code or Codex host install, explicit update, release metadata |

Cowork does not need `get.sienna.work` to install or start Sienna because the Marketplace Plugin contains checksum-verified Linux runtimes. A Cowork attempt to download a CLI is a Plugin packaging or resolution defect; update or reinstall the Plugin instead of asking the user to allow the download domain. Browser authorization may navigate the user's browser to provider-owned login domains outside the Cowork VM; do not broaden VM egress for those browser-only redirects unless a concrete failure requires it.

Treat DNS failure, connection refusal, TLS interception, and policy-denied responses as network problems, not authentication failures. Never print credentials while diagnosing them.
