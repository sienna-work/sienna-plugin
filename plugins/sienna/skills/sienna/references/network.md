# Cowork Network Requirements

Sienna does not modify network policy. When egress is denied, identify only the required category and ask the user or administrator to allow the exact production domain.

| Category | Domain | Used for |
| --- | --- | --- |
| Sienna sign-in | `auth.sienna.work` | Login and account connection |
| Creative analysis | `api.sienna.work` | Creative results and search |
| Meta Ads | `graph.facebook.com` | Meta Ads reads |
| Google Ads | `googleads.googleapis.com` | Google Ads reads |
| Adjust | `automate.adjust.com` | Adjust reads |
| Host CLI install/update | `get.sienna.work` | Host install and explicit update |

Cowork does not need `get.sienna.work` to install or start Sienna. If it asks to
download a CLI, update or reinstall the Plugin instead of allowing another
domain. Browser authorization may open provider-owned login domains outside the
Cowork VM; change VM egress only when a returned error identifies a required
domain.

Treat DNS failure, connection refusal, TLS interception, and policy-denied responses as network problems, not authentication failures. Never print credentials while diagnosing them.
