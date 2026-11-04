# Power Automate governance guideline

A guideline a client can approve in one meeting, written after a common trigger: an employee who owns business flows is leaving.

**Platform:** Power Platform admin center (inventory, environments), Power Automate (flow ownership), Entra ID (service account).

## Rules

| # | Rule | Why |
|---|---|---|
| 1 | Every business flow has at least two owners, or is owned by the environment's service account | A flow owned by one person stops when that account is disabled |
| 2 | A departure is announced to IT at least 30 days in advance, and every flow owned by the leaver is reassigned or rebuilt before the last day | Avoids broken processes discovered weeks later |
| 3 | A flow not run for 90 days is disabled, then deleted after a grace period, with the owner informed | Keeps the inventory and the attack surface small |
| 4 | Production flows run in a dedicated environment, deployed as solutions, with connections owned by the cloud-only service account | Separates personal productivity from business processes |
| 5 | Flows with AI actions (prompts, document processing) are registered with their capacity owner | AI actions consume capacity (see 04-finops-ai) |
| 6 | HTTP triggers and premium connectors require approval | Linked to the data policy in [power-platform-data-policy.md](power-platform-data-policy.md) |

## Service account

| Property | Value |
|---|---|
| Type | Cloud-only, no mailbox use by people, not synced from on-premises |
| Licence | Power Automate licence matching the flows it runs |
| Authentication | Phishing-resistant MFA, excluded from nothing except where a documented exception exists |
| Ownership | Named IT owner and a backup |
| Monitoring | Sign-in alerts, quarterly review of the flows it owns |

## Rollout

1. Inventory: flows per owner, last run, connectors, AI actions (Power Platform admin center inventory).
2. Secure what exists: add co-owners, move critical flows to the production environment under the service account.
3. Apply the rules: departure checklist in HR offboarding, monthly report of unused flows.

Licensing projections are unreliable until usage is known. Start with the inventory and decide licences on real numbers.
