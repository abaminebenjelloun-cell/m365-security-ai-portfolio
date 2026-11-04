# Layer 2: Power Platform data policy for Copilot Studio

**Platform:** Power Platform admin center (admin.powerplatform.microsoft.com) > Security > Data and privacy > Data policy (older menus: Policies > Data policies).
**Last reviewed:** November 2026 (Power Platform data policies and Copilot Studio connectors on Microsoft Learn).

## Why first

Without a data policy, any user can build an agent or flow wired to any of the 1,000+ connectors, including generic HTTP calls and public web knowledge (lesson L19). It is the fastest high-value control in agent governance.

## Design

| Decision | Value |
|---|---|
| Scope | Tenant level, applied to the default environment first (where most makers build) |
| Business group | Microsoft 365 connectors the organisation relies on (SharePoint, Outlook, Teams, OneDrive, Dataverse, Approvals) |
| Blocked group | See below |
| Default group for new connectors | Non-business (new connectors cannot be mixed with business data until reviewed) |
| Custom connectors and custom MCP servers | Inventoried, then classified explicitly (they are not governed by default) |

### Blocked in the first iteration

| Connector | Risk |
|---|---|
| HTTP | Arbitrary calls to any endpoint, data exfiltration path |
| Chat without Microsoft Entra ID authentication in Copilot Studio | Anonymous access to agents |
| Direct Line channels in Copilot Studio | Exposes agents outside the tenant |
| Facebook channel in Copilot Studio | Public social channel |
| WhatsApp channel in Copilot Studio | Public messaging channel |
| Knowledge source with public websites and data in Copilot Studio | Ungoverned web grounding for agents |

Connector display names change slightly over time. `Test-PowerPlatformDataPolicy.ps1` matches them by name and reports any it cannot find.

### Not blocked yet

HTTP-based **flow triggers** (When an HTTP request is received, HTTP Webhook) stay allowed until the flow inventory shows which business flows depend on them. Blocking before the inventory breaks processes silently.

## Environment strategy

| Environment | Who builds | Data policy | Capacity |
|---|---|---|---|
| Default | Everyone (personal productivity) | Strict (this policy) | Small allocation or none |
| Dedicated maker environment | Named heavy makers | Same, plus connectors approved for their use case | Capped allocation (see 03-finops-ai) |
| Production | Approved agents only, deployed as solutions | Same, plus approved custom connectors | Allocated per business owner |

## After saving

1. Run `Test-PowerPlatformDataPolicy.ps1`.
2. Tell makers which connectors are blocked and why, and how to request an exception.
3. Review custom connectors and MCP servers within 30 days.
