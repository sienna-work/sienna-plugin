# Cowork Network Requirements

Sienna does not modify network policy. When egress is denied, identify only the required category and ask the user or administrator to allow the exact production domain.

| Category | Domain | Used for |
| --- | --- | --- |
| Authentication | `auth.sienna.work` | Login, provider linking, Google token refresh |
| Creative analysis | `api.sienna.work` | Analyzed creative features and search |
| Meta Ads | `graph.facebook.com` | Meta Graph and Marketing API reads |
| Google Ads | `googleads.googleapis.com` | Google Ads queries |
| Adjust | `automate.adjust.com` | Adjust Report Service reads |
| Runtime install/update | `get.sienna.work` | Cowork bootstrap, host install, explicit update, release metadata |

Cowork needs `get.sienna.work` on first launch to download the architecture-specific CLI from an immutable version path. The bootstrap verifies the checksum published with the Plugin before installing it. Browser authorization may navigate the user's browser to provider-owned login domains outside the Cowork VM; do not broaden VM egress for those browser-only redirects unless a concrete failure requires it.

Treat DNS failure, connection refusal, TLS interception, and policy-denied responses as network problems, not authentication failures. Never print credentials while diagnosing them.
