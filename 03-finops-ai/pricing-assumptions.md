# Pricing assumptions

Every CHF figure depends on three assumptions. Write them on every report.

**Last reviewed:** October 2026 on Microsoft Learn (Copilot Studio billing rates and management). Rates and prices change: check the current page and the client's actual contract before quoting.

## 1. Unit price per credit

| Purchase model | Example price per credit | When it applies |
|---|---|---|
| Prepaid capacity pack (monthly packs of credits) | about USD 0.008 | Client bought packs through a licensing partner |
| Pay-as-you-go (billed through an Azure subscription) | about USD 0.01 | Environment linked to a pay-as-you-go billing policy |

Using the wrong one silently distorts every figure by about 25% (lesson L24). Check which model the tenant actually uses before converting.

## 2. Credits per feature (examples, verify)

| Feature | Example rate |
|---|---|
| Generative answer | 2 credits per answer |
| Agent action (trigger, reasoning step) | 5 credits per action |
| Tenant graph grounding | 10 credits per call |
| Agent flow actions | 13 credits per 100 actions |
| AI prompt, basic / standard / premium model | 0.1 / 1.5 / 10 credits per 1,000 tokens |
| Document processing | 8 credits per page |

Usage by a user who holds a Microsoft 365 Copilot licence, acting under their own identity, is generally not charged for many of these features. Autonomous agents, unlicensed and external users are. Check the current rules for the exact scenario.

## 3. Exchange rate

Use the rate finance uses for the invoice period, not a market rate of the day. The script takes it as a parameter (`--usd-to-chf`).

## Dates to remember

| Date | Change | Action |
|---|---|---|
| 1 November 2026 | New or renewed Power Platform and Dynamics 365 licences no longer include seeded AI Builder credits | Inventory flows with AI actions (document processing, prompts) before renewals, plan Copilot Credits capacity |
