# 01 · Copilot readiness

Prepare and protect data before Microsoft 365 Copilot can reach it. Core of the AI readiness offer ([03-consulting-and-adoption/ai-readiness-offer.md](../03-consulting-and-adoption/ai-readiness-offer.md)).

Based on a multi-workstream Microsoft 365 Copilot security programme for a Swiss mid-size group (1,000+ users). Everything here is rebuilt on a lab tenant.

| Workstream | Question | Deliverable |
|---|---|---|
| [WS1 Sensitivity labels](ws1-sensitivity-labels/) | Which content must never reach Copilot? | 4-level taxonomy as code, deploy and read-back scripts |
| [WS2 DLP](ws2-dlp/) | What stops sensitive content in prompts, answers and external sharing? | Copilot DLP runbook, external sharing DLP as code, test matrix |
| [WS3 Oversharing](ws3-oversharing/) | What can Copilot already see that it should not? | Inventory with exposure flags, delta report |
| [WS5 Web grounding](ws5-web-grounding/) | Can prompts leave the tenant through web search? | Cloud Policy configuration and verification |
| [WS6 Shadow AI](ws6-shadow-ai/) | Which other AI tools are already in use? | Discovery steps and sanction decision tree |

WS4 (agents and connectors) is in [02-agent-governance](../02-agent-governance/), WS7 in [04-finops-ai](../04-finops-ai/), WS8 in [05-secure-score-governance](../05-secure-score-governance/).

## Order

1. WS3 inventory (baseline, read-only)
2. WS1 labels to the pilot group
3. WS5 web grounding decision
4. WS2 DLP in simulation
5. WS6 discovery report
6. Decision gates with the sponsor, then enforcement by ring
