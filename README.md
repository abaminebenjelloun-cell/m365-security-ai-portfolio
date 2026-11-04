# Microsoft 365 Copilot, Power Platform & AI Governance Portfolio

How I prepare Microsoft 365 tenants for **Copilot**, drive its **adoption**, govern **Copilot Studio agents and Power Platform**, control **AI costs**, and package it as **consulting offers**. Methods, scripts, decisions and lessons from real engagements in Swiss organisations, rewritten from scratch for a personal lab tenant with synthetic data.

**No client data, names or identifiers appear in this repository.**

---

## Who I am

**Amine Benjelloun**, Microsoft 365 Technical Lead based in Geneva.

My whole career, about eight years, has been built around Microsoft. I started as a business analyst on Dynamics 365 (Dataverse) and on SharePoint and Teams governance programmes in large Canadian organisations, then moved to Switzerland, where I act as the Microsoft 365 practice lead at a Microsoft partner, working with regulated and public sector clients under revDSG and FINMA constraints.

Today my focus is **security, governance and AI**: helping organisations adopt Microsoft 365 Copilot and AI agents safely, with data ready before AI sees it, agents governed from the first build, costs under control, and people actually using what was bought.

I like turning project work into repeatable methods and offers, and I am growing towards an **AI solutions architect** role in the Microsoft ecosystem (Copilot Studio, Power Platform, Microsoft Foundry).

Languages: French and Arabic (native), English (fluent). Certifications: see my CV. LinkedIn: [linkedin.com/in/aminebenj](https://www.linkedin.com/in/aminebenj)

### What I have done

| Experience | Where it shows in this repository |
|---|---|
| Led a multi-workstream Microsoft 365 Copilot security programme for a Swiss mid-size group (1,000+ users) | [01 Copilot readiness](01-copilot-readiness/), [02 Agent governance](02-agent-governance/) |
| Governed Copilot Studio and Power Platform in production: first data policy, agent access, agent inventory analysis | [02 Agent governance](02-agent-governance/) |
| Wrote a Power Automate governance guideline approved by a client (ownership, offboarding, unused flows, service account) | [power-automate-governance.md](02-agent-governance/power-automate-governance.md) |
| Analysed Copilot Credits consumption and cost per use in CHF, set capacity caps per environment | [03 FinOps for AI](03-finops-ai/) |
| Built a booking agent in Copilot Studio for a client. When the client's data policy blocked it, kept the control and moved the use case to Microsoft 365 Copilot Chat | [05 field case](05-reference-agent-copilot-studio/README.md#field-case-a-real-agent-meets-governance) |
| Designed a reference agent with a per-persona evaluation set, to be built on my lab tenant | [05 Reference agent](05-reference-agent-copilot-studio/) |
| Trains client AI champions to drive Microsoft 365 Copilot adoption inside their companies | [consulting/ai-champions-programme.md](consulting/ai-champions-programme.md) |
| Created and industrialised a Microsoft 365 flash assessment offer, delivered to several clients, taught to colleagues | [consulting/assessment-method.md](consulting/assessment-method.md) |
| Designing an AI readiness offer (diagnostic, correction, protection, governance framework) | [consulting/ai-readiness-offer.md](consulting/ai-readiness-offer.md) |
| Built a Purview pre-sales kit (deck and reference guide) for the sales team | Employer material, not included. Pre-sales approach: [consulting/presales](consulting/presales/) |
| Ran a Secure Score programme from about 63% towards a 70% target: quick wins, nine ASR rules moved to Block after hunting review, Defender for Office 365 hardening, Conditional Access in report-only first | [04 Secure Score governance](04-secure-score-governance/) |
| Dynamics 365 and Dataverse projects, SharePoint and Teams governance for 5,000 users | Applied in the agent request and registry [specification](02-agent-governance/agent-registry-solution.md) |

## Sections

| # | Section | In one line | Main platforms |
|---|---|---|---|
| 01 | [Copilot readiness](01-copilot-readiness/) | Protect and prepare the data before Copilot sees it: labels, DLP for Copilot, oversharing, web grounding, shadow AI | Purview, SharePoint, Defender for Cloud Apps |
| 02 | [Agent governance](02-agent-governance/) | Who builds agents, with which connectors and MCP servers, who owns them, when they retire; a Dataverse request and registry solution | M365 admin center, Agent 365, Power Platform, Dataverse, Power Automate |
| 03 | [FinOps for AI](03-finops-ai/) | Copilot Credits to CHF per use, capacity caps, silent cost drivers | Power Platform admin center, Application Insights |
| 04 | [Secure Score governance](04-secure-score-governance/) | Raise Secure Score by waves, with a change log and accepted risks (run service) | Defender portal, Microsoft Graph |
| 05 | [Reference agent](05-reference-agent-copilot-studio/) | A real field case (client agent blocked by governance) and a reference agent designed under all the rules above, with a 20-case evaluation set | Copilot Studio |
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
| Methods, decisions, lessons learned, AI champions programme | Applied in real engagements, written up here without client data |
| Reference agent (05) | Field case from a real client build. Reference agent designed with its evaluation set, build on the lab tenant in progress |
| Agent request and registry solution (02) | Specification, build in progress |
| Python analysers (02 agent inventory, 03 FinOps) | Run on the synthetic data in this repository, outputs included |
| PowerShell deploy and read-back scripts (01, 02, 04) | Written for the lab tenant, not yet run end to end there. Use `-WhatIf` first |
| Test matrices | Filled only from real lab runs |

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

- Build the reference agent on the lab tenant, record its evaluation runs and export its solution (05); build the agent registry solution (02)
- The same use case on **Microsoft Foundry** with Azure AI Search in Switzerland North, with custom evaluators, to compare quality, control and cost
- Purview Endpoint DLP for Windows, then mobile; DSPM for AI as continuous monitoring
- Bicep for the Azure resources used by FinOps telemetry

## Side lab (outside work)

[private-ai-workspace](https://github.com/abaminebenjelloun-cell/private-ai-workspace) (private): a ChatGPT-class workspace on my own laptop GPU with four open-weight models in Ollama, zero-trust remote access with no open ports, an LLM threat model, side-by-side model comparison on my own questions, and an LLM built from scratch. It is how I learn what Copilot, Copilot Studio and Foundry do behind the scenes: context budgets, retrieval, prompt injection, cost per token.

## License

MIT, see [LICENSE](LICENSE).
