# AI champions programme (Microsoft 365 Copilot)

**Status:** offer design. Describes the champion role and how the programme runs; not presented as a delivered engagement.
**Last reviewed:** November 2026 against Microsoft's Copilot adoption guidance (adoption.microsoft.com, AI champion role and charter).

## Why a champions programme

Licences and security controls make Copilot **possible**. People make it **used**. A secured tenant where nobody knows what to ask Copilot, or where users fall back to unapproved AI tools, produces no value and new risk. Champions are employees in each department who help colleagues use Copilot well **and within the rules** set in the rest of this portfolio.

In this portfolio the programme is the people side of the AI readiness offer: it follows the protection phase, and it feeds back into governance (agent requests, shadow AI, cost).

## The champion role

Based on Microsoft's AI champion role and charter guidance, adapted to a governed rollout.

| Champions do | Champions do not own |
|---|---|
| Model responsible use of Copilot in their own work | IT support and troubleshooting |
| Share real workflow examples from their department | Licensing decisions |
| Run short peer sessions and answer "how do I" questions | Security, compliance or data protection approvals |
| Collect feedback, blockers and new use cases | Formal training curriculum |
| Point colleagues to the right resources and processes (labels, agent requests) | Adoption strategy or business outcomes |

**Profile:** curious, credible with colleagues, already experimenting, learns by doing, influences without authority. Not necessarily the most technical person in the team.

**Charter:** one page per programme, agreed with the sponsor and each champion's manager: purpose, who the champion supports, responsibilities and limits, escalation paths, expected time commitment, recognition and development.

**Coverage:** at least one champion per department or site, and per language region for multilingual Swiss organisations (French, German, Italian, English).

## Champion curriculum

What champions learn before they help others. Modules 3 to 5 are what makes this programme different from a generic adoption campaign: champions know the guardrails, not only the prompts.

| # | Module | Content | Link to the portfolio |
|---|---|---|---|
| 1 | How Copilot works | Grounding on work data, permissions, why answers differ between users | [01 Copilot readiness](../01-copilot-readiness/) |
| 2 | Prompting for real work | Goal, context, source, expectations; iterating; checking the answer and its citations | |
| 3 | Data rules in daily use | What Public, Internal, Confidential and Secret mean; why Secret content never appears in Copilot; what a DLP policy tip means | [WS1](../01-copilot-readiness/ws1-sensitivity-labels/), [WS2](../01-copilot-readiness/ws2-dlp/) |
| 4 | Approved and unapproved AI | Which AI tools are sanctioned, the approved alternative for each blocked one, why not to paste client data into public tools | [WS6 shadow AI](../01-copilot-readiness/ws6-shadow-ai/) |
| 5 | Agents: request, do not just build | When an agent is the right answer, how to request one, autonomy levels, cost awareness | [02 agent governance](../02-agent-governance/), [03 FinOps](../03-finops-ai/) |
| 6 | Department scenarios | Three to five scenarios per department from the Microsoft Scenario Library, adapted to local processes | |
| 7 | Leading peer sessions | 30-minute session format, collecting feedback, escalation paths | |

## Programme phases

Aligned with the champion track of Microsoft's Copilot adoption guidance (build the strategy, launch, generate excitement, share success and gather feedback, stay connected).

| Phase | Weeks | Activities | Output |
|---|---|---|---|
| 1. Set up | 1 to 2 | Sponsor and charter, nominate champions with their managers, define success measures and baseline | Charter, champion list, baseline |
| 2. Bootcamp | 3 to 4 | Two half-day sessions on modules 1 to 7, hands-on with the department's own scenarios | Trained champions, scenario list per department |
| 3. Launch with the pilot wave | 5 to 8 | Champions support the pilot group, run peer sessions, office hours, collect feedback | Feedback log, first success stories |
| 4. Scale | 9 to 16 | Wave by wave rollout, monthly champion community call, internal showcase of use cases | Adoption by department, use case backlog |
| 5. Run | Ongoing | Quarterly refresh on new features and rule changes, champion rotation, recognition | Living community |

## Measuring

| Measure | Source | Note |
|---|---|---|
| Active Copilot users and usage by app, by department | Copilot Dashboard; Microsoft 365 admin center usage reports | Report aggregated figures, respect the tenant's privacy settings for reports, involve the data protection officer (revDSG) |
| Use cases documented and reused | Champion feedback log | Qualitative value, not only usage |
| Agent requests through the process vs agents found in the inventory | 02 request and registry, inventory analysis | Shows whether governance is followed |
| Unapproved AI app usage trend | Defender for Cloud Apps discovery (WS6) | Should fall as Copilot adoption rises |
| DLP policy tips and overrides | Purview DLP reports (WS2) | Spikes point to training needs, not only to risky users |
| Champion activity | Sessions run, questions answered | Input for recognition |

## Deliverables of the offer

- Champion charter template and nomination guide
- Bootcamp material (modules 1 to 7), adapted to the client's labels, approved tools and agent process
- Session kit for champions: 30-minute format, prompt cards per department, FAQ
- Feedback log and monthly reporting template
- Handover to an internal programme owner after the scale phase

## Effort (template)

| Size | Champions | Indicative effort |
|---|---|---|
| Small | Up to 10 | 4 to 6 person-days |
| Medium | 10 to 30 | 8 to 12 person-days |
| Large | 30+ or several language regions | 15+ person-days |

Placeholder ranges to adjust per client, like the [estimate template](presales/estimate-template.md).

## References

- Microsoft Copilot adoption hub, champion track and resources: https://adoption.microsoft.com/copilot/
- Define your AI champion role and charter: https://adoption.microsoft.com/copilot/define-your-ai-champion-role-and-charter
- Microsoft Scenario Library: https://adoption.microsoft.com/scenario-library/
