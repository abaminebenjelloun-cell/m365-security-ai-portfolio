# 03 · FinOps for AI (WS7)

Copilot and agents have two cost layers that clients often mix up:

| Layer | Billed how | Example |
|---|---|---|
| Licences | Per user per month | Microsoft 365 Copilot, Agent 365, Power Automate premium |
| Capacity | Per use, in **Copilot Credits** | Agent answers, actions, tenant grounding, agent flow actions, AI prompts, document processing |

This section is about the second layer: knowing who consumes, what one use costs in CHF, and making sure one agent cannot drain the capacity of everyone else.

**Experience behind it:** a cost-per-use analysis in CHF from capacity exports, a pricing error caught and corrected before it reached the client (prepaid vs pay-as-you-go unit price), one maker identified as driving more than a third of all flow runs, per-environment capacity caps, and early warning on the end of seeded AI Builder credits.

## Files

| File | Purpose |
|---|---|
| [pricing-assumptions.md](pricing-assumptions.md) | Unit prices, rates per feature, exchange rate: every assumption a figure depends on |
| [capacity-playbook.md](capacity-playbook.md) | Allocation per environment, caps, alerts, pay-as-you-go decision, cost drivers and mitigations |
| `analyze_credits.py` | Cost per resource, per owner, per environment, per active day, runway, with reconciliation |
| `sample-data/copilot_credits_synthetic.csv` | One month of synthetic consumption for a fictional fiduciary |
| [sample-report/cost-report-synthetic.md](sample-report/cost-report-synthetic.md) | The report the script produces on that data |
| `telemetry/flow-metrics.kql` | Per-flow runs, failures and actions from Application Insights |

## Run

```bash
python3 03-finops-ai/analyze_credits.py 03-finops-ai/sample-data/copilot_credits_synthetic.csv \
    --usd-per-credit 0.008 --usd-to-chf 0.80 --allocation 25000 \
    --markdown 03-finops-ai/sample-report/cost-report-synthetic.md
```

## What the synthetic month shows

One agent flow polling a mailbox all day, every day, consumes more than half of the capacity, while the agents users actually value cost a few francs per active day. That pattern (a frequent schedule billing actions on every run, even when there is nothing to do) is the most common silent cost driver, and the first thing to look for in a real tenant.

## How it is used in a proposal

- **Before a build:** estimate credits per use from the rates, multiply by expected volume, and give the client a monthly range with assumptions.
- **During a pilot:** measure real consumption, compare with the estimate, set the cap.
- **In a managed service:** monthly cost report per agent and owner, runway, and recommendations.
