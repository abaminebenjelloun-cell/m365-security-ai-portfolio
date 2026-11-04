# WS5: Web grounding

Goal: decide explicitly whether Microsoft 365 Copilot may send web searches, and make the decision auditable.

**Platform:** Cloud Policy service for Microsoft 365 (config.office.com).
**Last reviewed:** November 2026. Policy names in the portal change often: search for "web" in the policy list.

## Why

With web search allowed, Copilot can turn the user's prompt into a search query sent to Bing. Prompts may contain client names, amounts or personal data. Many tenants leave the setting not configured, so behaviour follows changeable product defaults. A named policy makes it a documented control (ADR-005).

## Configuration

| Step | Where | Value |
|---|---|---|
| 1 | config.office.com > Customization > Policy management | Open the tenant-wide policy configuration, or create one scoped to the pilot group first |
| 2 | Search the settings for "web" | Setting that allows web search in Copilot |
| 3 | Set the value | Disabled for Microsoft 365 Copilot and Copilot Chat (or the option that matches the decision) |
| 4 | Name the configuration explicitly | For example `Lab - Copilot web search disabled` |
| 5 | Document | Owner, date, scope, reason, in the change log |

Priorities: a higher-priority Cloud Policy configuration that enables the same setting for the same users wins. Check every configuration targeting "All users" before concluding.

One tenant-wide slot: if the "All users" configuration already holds other settings (for example language), add the web search setting to it rather than creating a competing one, and rename it to reflect its purpose.

## Verification

| Test | Expected |
|---|---|
| Pilot user opens Copilot Chat | Web search toggle greyed out and not changeable |
| Pilot user asks a question that needs current web data | Copilot answers from work data only or says it cannot search the web |
| A user outside the scope (during the pilot) | Unchanged behaviour |

If web search stays enabled for some users, add the WS2 rule "Swiss sensitive data, no web search". It blocks web queries only when the prompt contains sensitive data.
