# WS5: Web grounding

**Goal:** decide explicitly whether Microsoft 365 Copilot may send web searches, and make that decision auditable.

**Platform:** Cloud Policy service for Microsoft 365 (config.office.com).
**Last reviewed:** November 2026. Policy names in the portal change often: search for "web" in the policy list.

## Why

When web search is allowed, Copilot can generate a search query from the user's prompt and send it to Bing. Prompts may contain client names, amounts or personal data. In many tenants the setting is simply **not configured**, so the behaviour depends on product defaults that can change. An explicit, named policy turns an unmanaged default into a documented control (ADR-005).

## Configuration

| Step | Where | Value |
|---|---|---|
| 1 | config.office.com > Customization > Policy management | Open the tenant-wide policy configuration, or create one scoped to the pilot group first |
| 2 | Search the settings for "web" | Setting that allows web search in Copilot |
| 3 | Set the value | Disabled for Microsoft 365 Copilot and Copilot Chat (or the option that matches the decision) |
| 4 | Name the configuration explicitly | For example `Lab - Copilot web search disabled` |
| 5 | Document | Owner, date, scope, reason, in the change log |

**Watch for conflicts.** Cloud Policy configurations have priorities. A higher-priority configuration that enables the same setting for the same users wins. Check every configuration that targets "All users" before concluding.

**Single tenant-wide slot.** If the tenant already uses the "All users" configuration for other settings (for example language), add the web search setting to it instead of creating a competing one, and rename it so its purpose is clear.

## Verification

| Test | Expected |
|---|---|
| Pilot user opens Copilot Chat | Web search toggle greyed out and not changeable |
| Pilot user asks a question that needs current web data | Copilot answers from work data only or says it cannot search the web |
| A user outside the scope (during the pilot) | Unchanged behaviour |

Complement with WS2 rule "Swiss sensitive data, no web search" if web search stays enabled for some users: it blocks web queries only when the prompt contains sensitive data.
