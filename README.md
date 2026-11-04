# Microsoft 365 Copilot, Power Platform & AI Governance Portfolio

How I prepare Microsoft 365 tenants for **Copilot**, govern **Copilot Studio agents and Power Platform**, control **AI costs**, and package it as **consulting offers**. Methods, scripts, decisions and lessons from real engagements in Swiss organisations, rewritten from scratch for a personal lab tenant with synthetic data.

**No client data, names or identifiers appear in this repository.**

---

## About me

Microsoft 365 Technical Lead at a Swiss Microsoft partner, acting as the M365 practice lead. Before that, business analyst on Dynamics 365 (Dataverse) and SharePoint and Teams governance programmes in large Canadian organisations.

| Experience | Where it shows in this repository |
|---|---|
| Led a multi-workstream Microsoft 365 Copilot security programme for a Swiss mid-size group (1,000+ users) | [01 Copilot readiness](01-copilot-readiness/), [02 Agent governance](02-agent-governance/), [03 FinOps](03-finops-ai/) |
| Created and industrialised a Microsoft 365 flash assessment offer, delivered to several clients, taught to colleagues | [consulting/assessment-method.md](consulting/assessment-method.md) |
| Designing an AI readiness offer (diagnostic, correction, protection) | [consulting/ai-readiness-offer.md](consulting/ai-readiness-offer.md) |
| Trains client AI champions to drive Microsoft 365 Copilot adoption inside their companies | [consulting/ai-champions-programme.md](consulting/ai-champions-programme.md) |
| Built a Purview pre-sales kit (deck and reference guide) for the sales team | Employer material, not included. Pre-sales approach: [consulting/presales](consulting/presales/) |
| Secure Score improvement programme to an agreed target, in waves | [04 Secure Score governance](04-secure-score-governance/) |
| Dynamics 365 and Dataverse projects, SharePoint and Teams governance for 5,000 users | [02 agent request and registry solution](02-agent-governance/agent-registry-solution.md) |
| Delivering the SC-300 identity and access course (November 2026) | |

Certifications: see my CV. Languages: French and Arabic (native), English (fluent).

## Sections

| # | Section | In one line | Main platforms |
|---|---|---|---|
| 01 | [Copilot readiness](01-copilot-readiness/) | Protect and prepare the data before Copilot sees it: labels, DLP for Copilot, oversharing, web grounding, shadow AI | Purview, SharePoint, Defender for Cloud Apps |
| 02 | [Agent governance](02-agent-governance/) | Who builds agents, with which connectors and MCP servers, who owns them, when they retire; a Dataverse request and registry solution | M365 admin center, Agent 365, Power Platform, Dataverse, Power Automate |
| 03 | [FinOps for AI](03-finops-ai/) | Copilot Credits to CHF per use, capacity caps, silent cost drivers | Power Platform admin center, Application Insights |
| 04 | [Secure Score governance](04-secure-score-governance/) | Raise Secure Score by waves, with a change log and accepted risks | Defender portal, Microsoft Graph |
| 05 | [Reference agent](05-reference-agent-copilot-studio/) | A Copilot Studio agent built under all the rules above, with a 20-case evaluation set | Copilot Studio |
| | [Consulting](consulting/) | Offers (flash assessment, AI readiness, **AI champions programme**) and pre-sales kit: workshop agenda, estimate template, proposal outline, demo script | |
| | [Docs](docs/) | Methodology, decision log (ADRs), lessons learned, lab setup, references | |

## How the pieces fit

```
  Flash assessment  ->  AI readiness  ->  AI champions  ->  Agent governance  ->  FinOps for AI  ->  Run
  (consulting/)         (01)              (consulting/)     (02)                  (03)               (04, monthly)
                                     \_____ proven on the reference agent (05) _____/
```

## Status, honestly

| Content | Status |
|---|---|
| Methods, decisions, lessons learned | Applied in production engagements, written up here without client data |
| PowerShell deploy and read-back scripts (01, 02, 04) | Written for the lab tenant; run them with `-WhatIf` first |
| Python analysers (02 agent inventory, 03 FinOps) | Run on the synthetic data in this repository, outputs included |
| Agent request and registry solution (02), reference agent (05) | Specification and evaluation set ready, **build in progress** on the lab tenant |
| Test matrices and evaluation results | Filled only from real lab runs |
| AI champions programme | From practice (champion training to drive Copilot adoption), written up as a method without client data |

## Working principles

- **Assess before you build.** Every engagement starts with a scored diagnostic.
- **Ring 0 first.** Controls start on a pilot group, in simulation where the product allows it.
- **Decision gates.** Enforcement is a sponsor decision taken on simulation data.
- **Configured is not verified.** Each section has a read-back script or check.
- **Everything is logged.** Change log with before, after, user impact and rollback.

[Methodology](docs/methodology.md) · [Decision log](docs/decision-log.md) · [Lessons learned](docs/lessons-learned.md)

## Quick start

```bash
# Python 3, standard library only, on synthetic data
python3 02-agent-governance/analyze_agent_inventory.py 02-agent-governance/sample-data/agent_inventory_synthetic.csv --today 2026-11-02 --active-users 02-agent-governance/sample-data/active_users_synthetic.txt
python3 03-finops-ai/analyze_credits.py 03-finops-ai/sample-data/copilot_credits_synthetic.csv
```

```powershell
# PowerShell 7, on a lab tenant (see docs/lab-setup.md)
. ./common/M365Lab.Common.ps1
Connect-LabIPPS -UserPrincipalName admin@contosofiduciaire.onmicrosoft.com
Assert-LabTenant -ExpectedTenantId <lab-tenant-guid> -Service ExchangeOnline
./01-copilot-readiness/ws1-sensitivity-labels/Deploy-SensitivityLabels.ps1 -ConfigPath ./01-copilot-readiness/ws1-sensitivity-labels/config/labels.json -WhatIf
```

## Swiss context

Designed for organisations under the revised Swiss Federal Act on Data Protection (revDSG / nFADP) and, where relevant, FINMA expectations on outsourcing and operational resilience. Azure resources default to Switzerland North and Switzerland West. Legal interpretation belongs to counsel or the compliance officer.

Fast-moving areas (Copilot, Copilot Studio billing, Agent 365, DLP for Copilot) carry a review date. Check Microsoft Learn before production use, and treat features marked **preview** as such.

## Roadmap

- Build and evaluate the reference agent (05) and the agent registry solution (02) on the lab tenant
- The same use case on **Microsoft Foundry** with Azure AI Search in Switzerland North, with an automated evaluation pipeline, to compare quality, control and cost
- Purview Endpoint DLP for Windows, then mobile; DSPM for AI as continuous monitoring
- Bicep for the Azure resources used by FinOps telemetry

## License

MIT, see [LICENSE](LICENSE).
