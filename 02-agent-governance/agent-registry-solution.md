# Agent request and registry solution (Power Platform)

> **Status: specification ready, build in progress on the lab tenant.**

Governance only works if requesting an agent is easier than building one in secret. This solution turns the lifecycle in [agent-365-lifecycle.md](agent-365-lifecycle.md) into a small Power Platform app: makers request, owners and IT approve, the register stays current, reviews happen on time.

It is useful on its own for tenants without Agent 365, and as the **intake process** in front of Agent 365 where it is licensed.

## Components

| Component | Technology | Purpose |
|---|---|---|
| Data | **Dataverse** tables in a solution | Single source of truth for agents, requests and reviews |
| Request and register app | **Model-driven app** (IT) and a **canvas app** in Teams (makers) | Request a new agent, see my agents, answer a review |
| Approval | **Power Automate** cloud flow with the Approvals connector | Business sponsor then IT approval, decision recorded |
| Review reminders | Scheduled cloud flow, **daily** (not every few minutes, see 03-finops-ai) | Reminds owners 14 days before the review date, escalates when overdue |
| Leaver check | Scheduled flow reading Entra account status | Flags agents whose owner is disabled |
| Deployment | Managed solution, environment variables, connection references owned by the service account | Clean move from dev to production |

## Dataverse model

| Table | Key columns |
|---|---|
| **Agent** | Name, platform (Copilot Studio, Agent Builder, third party), environment, owner (user), business sponsor (user), use case, data classification maximum (choice: Public, Internal, Confidential), autonomy level (A0 to A3), published to, monthly credit budget, status (Requested, Approved, Published, Under review, Retired), next review date |
| **Agent request** | Requested agent name, requester, justification, knowledge sources, tools and connectors, decision (Approved, Rejected), decided by, decision date, comment |
| **Agent review** | Agent (lookup), review date, still used (yes, no), owner confirmed, cost within budget, outcome (Keep, Change, Retire) |
| **Connector exception** | Agent (lookup), connector, reason, approved by, expiry date |

Security: Dataverse security roles. Makers see their own records, sponsors see their department, IT sees everything. No sensitive content stored, only metadata.

## Approval flow

```
Request submitted
  -> Check: classification maximum and connectors against the data policy (automatic)
  -> Approval 1: business sponsor (purpose, data, budget)
  -> Approval 2: IT (connectors, autonomy, environment)
  -> Approved: create Agent record (status Approved), notify maker with build guidelines
  -> Rejected: record reason, notify maker
```

## Why this belongs in a governance portfolio

- It covers **Power Apps, Power Automate and Dataverse** in one artefact, around a real governance need.
- It follows its own rules: solution-based ALM, service account ownership, daily rather than frequent schedules, data policy compliance.
- It produces the evidence an auditor asks for: who requested, who approved, when it was last reviewed.

## Build checklist

- [ ] Solution `AgentGovernance` with publisher prefix, created in a dev environment
- [ ] Four tables with relationships and choices
- [ ] Model-driven app with views: active agents, overdue reviews, agents with disabled owners
- [ ] Canvas app for makers, embedded in Teams
- [ ] Approval flow and two scheduled flows, connection references owned by the service account
- [ ] Export as managed solution, unpack into `02-agent-governance/agent-registry/solution/` with `pac solution unpack`
- [ ] Screenshots of the apps and a run history of the approval flow in `02-agent-governance/agent-registry/screenshots/`
