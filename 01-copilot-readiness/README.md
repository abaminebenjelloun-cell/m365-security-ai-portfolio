# 01 · Copilot readiness

Prepare and protect the data before Microsoft 365 Copilot can reach it. This is the core of the AI readiness offer ([consulting/ai-readiness-offer.md](../consulting/ai-readiness-offer.md)).

**Experience behind it:** a six-workstream Copilot security engagement for a Swiss industrial group (about 1,400 users, E5), plus Copilot readiness work for SMEs and the public sector. Everything here is rebuilt on a lab tenant.

| Workstream | Question it answers | Deliverable in this folder |
|---|---|---|
| [WS1 Sensitivity labels](ws1-sensitivity-labels/) | Which content must never reach Copilot? | 4-level taxonomy as code, deploy and read-back scripts |
| [WS2 DLP](ws2-dlp/) | What stops sensitive content in prompts, answers and external sharing? | Copilot DLP runbook, external sharing DLP as code, test matrix |
| [WS3 Oversharing](ws3-oversharing/) | What can Copilot already see that it should not? | Inventory with exposure flags, delta report |
| [WS5 Web grounding](ws5-web-grounding/) | Can prompts leave the tenant through web search? | Cloud Policy configuration and verification |
| [WS6 Shadow AI](ws6-shadow-ai/) | Which other AI tools are already in use? | Discovery steps and sanction decision tree |

WS4 (agents and connectors) lives in [02-agent-governance](../02-agent-governance/), WS7 in [03-finops-ai](../03-finops-ai/), WS8 in [04-secure-score-governance](../04-secure-score-governance/).

## Order of execution

1. WS3 inventory (baseline, read-only)
2. WS1 labels to the pilot group
3. WS5 web grounding decision
4. WS2 DLP in simulation
5. WS6 discovery report
6. Decision gates with the sponsor, then enforcement by ring
