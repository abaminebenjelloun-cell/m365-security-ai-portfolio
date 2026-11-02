# Microsoft 365 Security & AI Governance Portfolio

Field-tested methods, scripts and decisions from Microsoft 365 security and AI governance work in Swiss organisations: making tenants ready for **Microsoft 365 Copilot**, governing **Copilot Studio and agents**, controlling **AI costs**, and running **security posture** with evidence.

Everything here is rewritten from scratch and validated on a personal lab tenant with synthetic data. **No client data, names or identifiers appear in this repository.**

---

## What you will find

| # | Section | In one line | Main platforms |
|---|---|---|---|
| 01 | [Copilot readiness](01-copilot-readiness/) | Protect and prepare the data before Copilot sees it: labels, DLP for Copilot, oversharing, web grounding, shadow AI | Microsoft Purview, SharePoint, Defender for Cloud Apps |
| 02 | [Agent governance](02-agent-governance/) | Control who builds agents, with which connectors, who owns them, and when they retire | M365 admin center, Agent 365, Power Platform admin center, Entra ID |
| 03 | [FinOps for AI](03-finops-ai/) | Turn Copilot Credits into CHF per use, cap capacity, avoid silent burn | Power Platform admin center, Application Insights |
| 04 | [Secure Score governance](04-secure-score-governance/) | Raise Microsoft Secure Score by waves, with a change log and accepted risks | Microsoft Defender portal, Microsoft Graph |
| 05 | [Reference agent](05-reference-agent-copilot-studio/) | A Copilot Studio agent built under all the rules above, with a 20-query evaluation | Copilot Studio |
| | [Consulting offers](consulting/) | How the work is packaged: flash assessment and AI readiness offer | |
| | [Docs](docs/) | Methodology, decision log (ADRs), lessons learned, lab setup, references | |

## How the pieces fit

```
  Flash assessment  ->  AI readiness  ->  Agent governance  ->  FinOps for AI  ->  Run
  (consulting/)         (01)              (02)                  (03)               (04, monthly)
                                     \_____ proven with the reference agent (05) _____/
```

The Copilot readiness engagement is organised in workstreams, referenced throughout the repository:

| ID | Workstream | Folder |
|---|---|---|
| WS1 | Sensitivity labels | `01-copilot-readiness/ws1-sensitivity-labels` |
| WS2 | DLP (Copilot and external sharing) | `01-copilot-readiness/ws2-dlp` |
| WS3 | Oversharing | `01-copilot-readiness/ws3-oversharing` |
| WS4 | Agents and connectors | `02-agent-governance` |
| WS5 | Web grounding | `01-copilot-readiness/ws5-web-grounding` |
| WS6 | Shadow AI | `01-copilot-readiness/ws6-shadow-ai` |
| WS7 | FinOps for AI | `03-finops-ai` |
| WS8 | Secure Score governance | `04-secure-score-governance` |

## Working principles

- **Assess before you build.** Every engagement starts with a scored diagnostic.
- **Ring 0 first.** Controls start on a pilot group, in simulation where the product allows it.
- **Decision gates.** Enforcement is a sponsor decision taken on simulation data, never a default.
- **Configured is not verified.** Each section ships a `Test-*` script or a written check that reads the configuration back from the tenant.
- **Everything is logged.** Change log with before, after, user impact and rollback.

Details: [docs/methodology.md](docs/methodology.md) · Why each choice was made: [docs/decision-log.md](docs/decision-log.md) · What went wrong before: [docs/lessons-learned.md](docs/lessons-learned.md)

## Quick start (lab)

1. Build a lab tenant with synthetic data: [docs/lab-setup.md](docs/lab-setup.md).
2. Read the README of the section you need.
3. Every change script supports `-WhatIf`. Every `Test-*` script is read-only.

```powershell
. ./common/M365Lab.Common.ps1
Connect-LabIPPS -UserPrincipalName admin@contosofiduciaire.onmicrosoft.com
Assert-LabTenant -ExpectedTenantId <lab-tenant-guid> -Service ExchangeOnline
./01-copilot-readiness/ws1-sensitivity-labels/Deploy-SensitivityLabels.ps1 -ConfigPath ./01-copilot-readiness/ws1-sensitivity-labels/config/labels.json -WhatIf
```

```bash
# FinOps analysis and agent inventory analysis on synthetic data (Python 3, standard library only)
python3 03-finops-ai/analyze_credits.py 03-finops-ai/sample-data/copilot_credits_synthetic.csv
python3 02-agent-governance/analyze_agent_inventory.py 02-agent-governance/sample-data/agent_inventory_synthetic.csv
```

## Scope and honesty

| This repository is | It is not |
|---|---|
| Methods and working lab code you can adapt | Legal advice or a compliance certification |
| Results from a synthetic lab tenant | A copy of any client deliverable or employer material |
| Explicit about **preview** vs generally available features | A guarantee that menus, rates or licences have not changed since each "verified on" date |

Fast-moving areas (Copilot, Copilot Studio billing, Agent 365, DLP for Copilot) carry a **verified on** date. Check Microsoft Learn before production use.

## Swiss context

Designed for organisations under the revised Swiss Federal Act on Data Protection (revDSG / nFADP) and, where relevant, FINMA expectations on outsourcing and operational resilience. Data residency defaults to Switzerland North and Switzerland West. The repository gives the technical perspective; interpretation of law and contracts belongs to legal counsel or the compliance officer.

## Roadmap

- The reference use case rebuilt on **Microsoft Foundry** with Azure AI Search in Switzerland North, with an automated evaluation pipeline.
- **Purview Endpoint DLP** for Windows devices, then mobile.
- **DSPM for AI** as the continuous version of the oversharing diagnostic.
- Infrastructure as code (Bicep) for the Azure resources used by FinOps telemetry.

## License

MIT, see [LICENSE](LICENSE).
