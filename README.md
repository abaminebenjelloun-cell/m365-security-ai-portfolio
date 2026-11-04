# Microsoft 365 Copilot, Power Platform & AI Governance Portfolio

How I prepare Microsoft 365 tenants for Copilot, drive adoption, govern Copilot Studio agents and Power Platform, and control AI costs. Methods and lessons come from real engagements in Swiss organisations, rewritten for a personal lab tenant with synthetic data. No client data, names or identifiers appear here.

## Who I am

**Amine Benjelloun**, Microsoft 365 Technical Lead based in Geneva.

My whole career, about eight years, has been built around Microsoft, always as a consultant facing clients in French and English. I have led Microsoft programmes, from Dynamics 365 (Dataverse) to SharePoint and Teams governance, first in Canada and now in Switzerland, and I support pre-sales with workshops, offers and demos. Today I lead the Modern Workplace side of a Microsoft partner. My clients are mainly mid to large financial institutions, public sector organisations and watchmakers, in regulated environments (revDSG, FINMA).

My current focus is **security, governance and AI**: helping organisations adopt Microsoft 365 Copilot and AI agents safely, with data ready before AI sees it, agents governed from the first build, costs under control, and people actually using what was bought.

I like turning project work into repeatable methods and offers, and I am growing towards an **AI solutions architect** role in the Microsoft ecosystem (Copilot Studio, Power Platform, Microsoft Foundry).

Languages: French and Arabic (native), English (fluent). Certifications: see my CV. LinkedIn: [linkedin.com/in/aminebenj](https://www.linkedin.com/in/aminebenj)

### What I have done

| Experience | Where |
|---|---|
| Led a multi-workstream Copilot security programme for a Swiss mid-size group (1,000+ users) | [01](01-copilot-readiness/), [02](02-agent-governance/) |
| Governed Copilot Studio and Power Platform in production: first data policy, agent access, agent inventory analysis | [02](02-agent-governance/) |
| Built a booking agent in Copilot Studio for a client. When the client's data policy blocked it, kept the policy and moved the use case to Microsoft 365 Copilot Chat | [06 field case](06-reference-agent-copilot-studio/README.md#field-case-a-real-agent-meets-governance) |
| Training client AI champions to drive Copilot adoption | [ai-champions-programme.md](03-consulting-and-adoption/ai-champions-programme.md) |
| Created a Microsoft 365 flash assessment offer based on the CIS benchmark, delivered to several clients and taught to colleagues. It opens follow-up contracts sold as prepaid blocks of hours | [assessment-method.md](03-consulting-and-adoption/assessment-method.md) |
| Analysed Copilot Credits consumption and cost per use in CHF, set capacity caps per environment | [04](04-finops-ai/) |
| Ran a Secure Score programme from about 63% towards 70%: quick wins, nine ASR rules moved to Block after hunting review, Defender for Office 365 hardening, Conditional Access in report-only first | [05](05-secure-score-governance/) |
| Wrote a Power Automate governance guideline approved by a client | [power-automate-governance.md](02-agent-governance/power-automate-governance.md) |
| Designing an AI readiness offer | [ai-readiness-offer.md](03-consulting-and-adoption/ai-readiness-offer.md) |
| Built a Purview pre-sales kit for the sales team (employer material, not included) | [presales](03-consulting-and-adoption/presales/) |
| Dynamics 365 and Dataverse projects, SharePoint and Teams governance for 5,000 users | [registry specification](02-agent-governance/agent-registry-solution.md) |

## Sections

| # | Section | Content |
|---|---|---|
| 01 | [Copilot readiness](01-copilot-readiness/) | Labels, DLP for Copilot, oversharing, web grounding, shadow AI |
| 02 | [Agent governance](02-agent-governance/) | Agent baseline, Power Platform data policy, MCP, Agent 365 lifecycle, Dataverse request and registry solution |
| 03 | [Consulting and adoption](03-consulting-and-adoption/) | AI readiness offer, AI champions, CIS-based flash assessment, pre-sales kit |
| 04 | [FinOps for AI](04-finops-ai/) | Copilot Credits to CHF per use, capacity caps, cost drivers |
| 05 | [Secure Score governance](05-secure-score-governance/) | The programme step by step, change log, monthly snapshot |
| 06 | [Reference agent](06-reference-agent-copilot-studio/) | Field case, reference agent design, 20-case evaluation set |
| | [Docs](docs/) | Methodology, decision log, lessons learned, lab setup, references |

```
  Flash assessment -> AI readiness -> AI champions -> Agent governance -> FinOps for AI -> Run
  (03)                (01)            (03)            (02)                (04)             (05)
```

## Status

| Content | Status |
|---|---|
| Methods, decisions, lessons, AI champions programme | From real engagements, without client data |
| 06 | Field case is real. Reference agent designed, lab build in progress |
| 02 registry solution | Specification, build in progress |
| Python analysers (02, 04) | Run on the synthetic data here, outputs included |
| PowerShell scripts (01, 02, 05) | Written for the lab tenant, not yet run end to end. Use `-WhatIf` first |
| Test matrices and evaluation results | Filled only from real runs |

## Principles

- Assess before building.
- Pilot group first, simulation where the product allows it.
- The sponsor decides enforcement, on simulation data.
- A setting counts only once read back from the tenant.
- Every change is logged with before, after, impact and rollback.

[Methodology](docs/methodology.md) · [Decision log](docs/decision-log.md) · [Lessons learned](docs/lessons-learned.md)

## Quick start

```bash
# Python 3, standard library only, synthetic data
python3 02-agent-governance/analyze_agent_inventory.py 02-agent-governance/sample-data/agent_inventory_synthetic.csv --today 2026-11-02 --active-users 02-agent-governance/sample-data/active_users_synthetic.txt
python3 04-finops-ai/analyze_credits.py 04-finops-ai/sample-data/copilot_credits_synthetic.csv
```

```powershell
# PowerShell 7, lab tenant (see docs/lab-setup.md)
. ./common/M365Lab.Common.ps1
Connect-LabIPPS -UserPrincipalName admin@contosofiduciaire.onmicrosoft.com
Assert-LabTenant -ExpectedTenantId <lab-tenant-guid> -Service ExchangeOnline
./01-copilot-readiness/ws1-sensitivity-labels/Deploy-SensitivityLabels.ps1 -ConfigPath ./01-copilot-readiness/ws1-sensitivity-labels/config/labels.json -WhatIf
```

## Swiss context

Built for organisations under revDSG and, where relevant, FINMA expectations on outsourcing and operational resilience. Azure resources default to Switzerland North and West. Legal interpretation belongs to counsel or the compliance officer. Copilot, Copilot Studio billing, Agent 365 and DLP for Copilot change often: pages carry a review date, and preview features are marked as such.

## Roadmap

- Build the reference agent in the lab and record its evaluation runs (06); build the registry solution (02)
- Same use case on Microsoft Foundry with Azure AI Search in Switzerland North, to compare quality, control and cost
- Purview Endpoint DLP for Windows, then mobile; DSPM for AI
- Bicep for the FinOps telemetry resources

## Side lab

[private-ai-workspace](https://github.com/abaminebenjelloun-cell/private-ai-workspace) (private, outside work): four open-weight models on my laptop GPU with Ollama, remote access with no open ports, an LLM threat model, model comparison on my own questions, and learning to build an LLM from scratch. It shows me what Copilot and Foundry do underneath: context limits, retrieval, prompt injection, cost per token.

## License

MIT, see [LICENSE](LICENSE).
