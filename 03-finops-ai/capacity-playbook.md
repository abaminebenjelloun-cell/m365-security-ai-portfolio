# Capacity playbook

**Platform:** Power Platform admin center > Licensing > Copilot Studio (capacity, environments, alerts), Billing policies for pay-as-you-go.

## 1. Allocate, do not share

Capacity is allocated per environment (lesson L20). Without allocation, the first agent to consume wins and the others stop.

| Environment | Allocation | Draw from tenant pool | Pay-as-you-go |
|---|---|---|---|
| Default | Small, or none | Off | Off |
| Dedicated maker environment (heavy maker isolated) | Monthly cap sized on measured volume | Off, so the cap is a real cap | Off |
| Production | Per business owner budget | Decision per owner | Only if the owner accepts an open budget |

A capped environment **stops AI steps when the cap is reached**, until the next month. Tell the business owner before go-live, or they discover the cap as an outage.

## 2. Alerts

Turn on capacity alerts for each allocated environment, sent to IT and the business owner. An Azure Cost Management budget on a pay-as-you-go subscription alerts but does not stop consumption. The cap is the stop.

## 3. Restrict who can build

Assign the Copilot Studio authoring permission to a security group. Fewer makers, fewer surprise agents.

## 4. Cost drivers and mitigations

| Driver | Why it costs | Mitigation |
|---|---|---|
| Frequent schedules on agent flows | Billed per action on every run, even when nothing happens. A 5-minute schedule is roughly 290 times a daily one | Cheap checks first, terminate early, poll with a classic flow, call the agent only when there is work |
| Reasoning models | Much higher cost per interaction | Per-agent limit, use only where the quality gain is proven |
| Tenant graph grounding on every turn | Highest per-call rate | Scope knowledge, ground only when needed |
| Testing in production environments | Real runs bill; agent flow test runs from the designer do not bill agent flow actions | Test in the designer, measure on a pilot group |
| Seeded AI Builder credits ending | Flows with AI actions fail or move to paid capacity | Inventory and re-plan before renewal dates |

## 5. Telemetry for per-flow analysis

Native reports aggregate per environment and day. For per-flow detail, export Power Automate telemetry to **Application Insights in Switzerland North** and query it with `telemetry/flow-metrics.kql`. Telemetry is for trends, not billing, and can contain user identifiers: set retention and access accordingly (revDSG).
