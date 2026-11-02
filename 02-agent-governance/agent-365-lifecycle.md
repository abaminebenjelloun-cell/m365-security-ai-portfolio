# Layer 3: agent lifecycle and Agent 365

**Verified on:** 2026-11-02 against Microsoft Learn (Microsoft Agent 365 overview).

## Agent 365 in two sentences

Microsoft Agent 365 is the control plane for agents: a registry and lifecycle across Microsoft 365, Entra, Defender, Purview and Intune, covering Microsoft, Copilot Studio and third-party agents. It has been **generally available since 1 May 2026 for the commercial segment, licensed per user**, as a standalone licence or as part of Microsoft 365 E7, and at least one user must hold a qualifying licence to enable it.

## Licensing reasoning for a client

| Situation | Recommendation |
|---|---|
| Few agents, mostly Microsoft and a handful of Copilot Studio agents | Layers 1 and 2 plus the register in this folder. No Agent 365 yet |
| Dozens of agents, several platforms, third-party agents, regulated client | Agent 365 for the registry, identity and monitoring integration |
| Client already moving to Microsoft 365 E7 | Agent 365 is included, design the lifecycle around it from day one |

Agent 365 is a **per-user governance licence**. It does not pay for what agents consume: Copilot Studio capacity (Copilot Credits) is a separate, usage-based cost (see [03-finops-ai](../03-finops-ai/)). Mixing the two up is a common pricing mistake in proposals.

## Lifecycle

```
 Request -> Register -> Approve -> Publish -> Review (quarterly) -> Change or Retire
                |                                  |
                owner, sponsor, data, permissions, autonomy level, cost centre
```

| Stage | Gate | Evidence |
|---|---|---|
| Request | Use case, business owner, data sources named | Request form or ticket |
| Register | Entry in `agent-register-template.csv` (or the Agent 365 registry) | Register line |
| Approve | Data policy compliant, knowledge sources inside SharePoint permissions (no uploaded copies of sensitive files), autonomy level accepted | Approval record |
| Publish | Published to a scoped group, not org-wide by default | Sharing setting |
| Review | Owner still employed, agent used in the last 90 days, cost within budget | Review date updated |
| Retire | Owner left, unused for 90 days, or duplicate | Agent blocked, then deleted after a grace period |

## Autonomy levels

| Level | Description | Extra control |
|---|---|---|
| A0 | Answers questions from approved knowledge | Data policy, labels |
| A1 | Drafts actions, a human executes | As A0 |
| A2 | Executes actions after human approval | Approval step in the flow, audit trail |
| A3 | Executes autonomously on a trigger | Business owner sign-off, capacity cap, monitoring, kill switch documented |

## Findings worth looking for in any inventory

- Agents owned by **admin accounts** (built while testing, never handed over).
- **Duplicates** of the same agent by different makers.
- Agents whose knowledge is **uploaded files** with HR, finance or third-party content: those copies bypass SharePoint permissions.
- Agents using **MCP servers**, especially preview ones, and custom MCP servers that no data policy governs.
- Frontier or preview agents enabled in production.
