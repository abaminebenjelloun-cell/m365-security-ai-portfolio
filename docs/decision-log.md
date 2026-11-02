# Decision log

Architecture decisions behind this portfolio, written as short ADRs. Each one records the context, the decision, the alternatives and the consequences, so a client or a successor can see why, not only what.

---

## ADR-001: Four flat labels, no sublabels at launch

- **Context:** Users must label correctly from day one. Complex taxonomies get ignored or mislabelled.
- **Decision:** Four levels: Public, Internal, Confidential, Secret. No sublabels in phase 1. Scope: files and emails. Groups and sites scope deferred until oversharing (WS3) is under control.
- **Alternatives:** Microsoft default taxonomy with sublabels; department-specific labels.
- **Consequences:** Easy adoption and training. Department-specific protection needs come later as sublabels if the business asks.

## ADR-002: "Secret" is excluded from Copilot through usage rights, not only DLP

- **Context:** Some content must never appear in a Copilot answer, even for authorised readers.
- **Decision:** The Secret label applies encryption with admin-defined rights that exclude `EXTRACT` (and `PRINT`, `FORWARD`, `EXPORT`, `OBJMODEL`, `OWNER`). A DLP for Copilot rule blocking Secret is added as a second layer.
- **Alternatives:** DLP only; restricted audience on the label.
- **Consequences:** Two independent controls. Copilot cannot ground on Secret content even if a DLP rule is misconfigured, except for the Rights Management owner (the person who applied the label), which is why the DLP rule matters. Access control itself still relies on SharePoint and OneDrive permissions (see ADR-006).

## ADR-003: "Confidential" stays usable by Copilot, enforcement is a client decision

- **Context:** Most business content is Confidential. Blocking it from Copilot removes most of the value.
- **Decision:** Confidential keeps `EXTRACT` (co-author rights). A DLP for Copilot rule on Confidential runs in **measurement mode** first. Enforcement is a decision gate based on the simulation volume.
- **Consequences:** Value preserved, risk measured, decision documented.

## ADR-004: DLP starts in simulation, scoped to a pilot account

- **Context:** DLP false positives block business processes and destroy trust in the project.
- **Decision:** All new DLP policies are created in `TestWithNotifications` mode, scoped to ring 0 where the location allows it.
- **Consequences:** Slower first enforcement, far fewer incidents. SharePoint rules are tenant-wide by nature and stay in simulation longer (lesson L9).

## ADR-005: Web grounding off for Copilot, managed explicitly

- **Context:** Prompts can contain sensitive data that would be sent to a web search service. In many tenants web search is simply "not configured".
- **Decision:** Set the Cloud Policy setting that controls web search in Copilot explicitly, with a named policy and documented scope.
- **Consequences:** An implicit default becomes an auditable control. Re-enabling it later is a documented decision.

## ADR-006: Oversharing remediation is a prerequisite, not an option

- **Context:** Copilot answers with whatever a user can reach. Labels without permission hygiene protect little.
- **Decision:** A full SharePoint and OneDrive inventory is produced before enforcement, and repeated to track cleanup (delta report).
- **Consequences:** Cleanup progress is measurable. Restricted Content Discovery or Restricted SharePoint Search can be used as temporary measures, presented as such, not as remediation.

## ADR-007: Agents are governed at three layers

- **Context:** Agents arrive from Microsoft, third parties, and users building in Copilot Studio or Agent Builder.
- **Decision:** (1) Tenant agent settings in the Microsoft 365 admin center: allowed agent types, Frontier previews off in production, sideloading off. (2) Power Platform data policy limiting connectors for Copilot Studio. (3) Lifecycle: inventory, owner, review, block, retire, with Agent 365 where licensed.
- **Consequences:** Most controls need no extra licence. Agent 365 adds registry and lifecycle at scale when the client licenses it.

## ADR-008: Capacity is allocated per environment with a cap, pay-as-you-go off by default

- **Context:** Without allocation, one heavy agent can consume the shared capacity. Pay-as-you-go turns that into an open-ended bill.
- **Decision:** Allocate Copilot Credits to named environments, isolate heavy makers in their own capped environment, alerts on, pay-as-you-go linked only where a business owner accepts the budget.
- **Consequences:** Predictable cost. A capped flow can stop mid-month, so the business owner must be informed of that behaviour.

## ADR-009: Copilot Studio for the reference agent, Foundry as the next step

- **Context:** The reference agent (section 05, build in progress) answers HR policy questions from SharePoint content for internal users.
- **Decision:** Copilot Studio, because the knowledge lives in Microsoft 365, users authenticate with Entra ID, and governance (data policy, capacity, sharing) is native.
- **When Foundry would win:** custom orchestration, own retrieval index (Azure AI Search), model choice, external users at scale, or a full automated evaluation pipeline.
- **Consequences:** Fast to build and govern. Limits on retrieval tuning are accepted and documented.

## ADR-010: Secure Score is governed by waves and a change log, not chased

- **Context:** Secure Score improves quickly by toggling settings, sometimes with real user impact.
- **Decision:** Agree a target with the sponsor, group recommendations into waves by user impact, log every change, and use "risk accepted" or "alternate mitigation" statuses with a written reason instead of leaving items open.
- **Consequences:** The score rises without surprises, and every point is defensible in an audit.
