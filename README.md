# Copilot Security Blueprint

A field-tested, reproducible method to make a Microsoft 365 tenant **ready for Copilot and AI agents**: protect the data, govern the agents, control the cost, and prove it.

Built from real Microsoft 365 Copilot security engagements in Swiss organisations (industrial group, public sector, SMEs, financial sector context), rewritten from scratch and validated in a personal lab tenant. **No client data, names or identifiers appear in this repository.**

---

## Why this exists

Microsoft 365 Copilot answers with everything a user can already reach. In most tenants that means overshared SharePoint sites, unlabelled sensitive files, ungoverned connectors and agents nobody owns. Turning Copilot on without preparing the data turns old permission debt into a new data leak, and agents without capacity rules turn into a surprise bill.

This blueprint covers the full path:

```
 Assess  ->  Make data ready  ->  Protect  ->  Govern agents  ->  Control cost  ->  Prove it
 (WS3,WS8)    (WS1, WS3)         (WS2,WS5,WS6)   (WS4)              (WS7)           (tests, evaluation)
```

## Workstreams

| # | Workstream | What it delivers | Main platform |
|---|---|---|---|
| [WS1](ws1-purview-sensitivity-labels/) | Sensitivity labels | 4-level taxonomy where the top level is excluded from Copilot grounding (no `EXTRACT` right) | Microsoft Purview |
| [WS2](ws2-purview-dlp/) | Data Loss Prevention | DLP for Microsoft 365 Copilot and Copilot Chat, plus external sharing DLP with tiered enforcement | Microsoft Purview |
| [WS3](ws3-oversharing/) | Oversharing | SharePoint and OneDrive inventory, exposure flags, delta report between two snapshots | SharePoint admin, PowerShell |
| [WS4](ws4-agents-and-connectors/) | Agents and connectors | Power Platform data policy for Copilot Studio, agent access group, Agent 365 lifecycle, agent inventory analysis, Power Automate governance | M365 admin center, Power Platform admin center, Entra |
| [WS5](ws5-web-grounding/) | Web grounding | Explicit, auditable control of web search in Copilot | Cloud Policy service |
| [WS6](ws6-shadow-ai/) | Shadow AI | Discovery of generative AI apps and a sanction decision tree | Defender for Cloud Apps |
| [WS7](ws7-finops-ai/) | FinOps for AI | Copilot Credits consumption analysis, cost per use in CHF, capacity caps, telemetry | Power Platform admin center, Azure Application Insights |
| [WS8](ws8-secure-score-governance/) | Secure Score governance | Baseline, target, waves, change log, risk acceptance, monthly snapshot | Microsoft Defender portal, Microsoft Graph |
| [Reference agent](reference-agent/) | A Copilot Studio agent built under these rules | Design, guardrails, 20-query evaluation | Copilot Studio |

## Method in one page

- **Assess before you build.** A scored assessment (see [assessment method](docs/assessment-method.md)) and an AI readiness diagnostic (see [AI readiness method](docs/ai-readiness-method.md)) come first.
- **Ring 0 first.** Every control starts on a pilot group, in simulation mode where the product allows it.
- **Decision gates.** Enforcement is a client decision taken on simulation data, never a default.
- **Configured is not verified.** Every workstream ships a `Test-*` script or a written check that reads the configuration back from the tenant. A setting only counts once it has been read back.
- **Everything is logged.** Each change goes into a change log with before state, after state, user impact and rollback.

Details: [docs/methodology.md](docs/methodology.md).

## Repository layout

```
copilot-security-blueprint/
├── docs/                              method, decisions, lessons learned, lab setup
├── common/                            shared PowerShell helpers (connection, tenant check, logging)
├── ws1-purview-sensitivity-labels/
├── ws2-purview-dlp/
├── ws3-oversharing/
├── ws4-agents-and-connectors/
├── ws5-web-grounding/
├── ws6-shadow-ai/
├── ws7-finops-ai/
├── ws8-secure-score-governance/
├── reference-agent/
└── .github/workflows/                 lint for PowerShell and Python
```

## Quick start (lab)

1. Build a lab tenant with synthetic data: [docs/lab-setup.md](docs/lab-setup.md).
2. Read [docs/methodology.md](docs/methodology.md) and the README of the workstream you need.
3. Every script starts in **read-only or `-WhatIf` mode**. Review the configuration file in `config/` before you deploy.

```powershell
# Example: deploy the label taxonomy to the lab, then verify it
. ./common/Blueprint.Common.ps1
./ws1-purview-sensitivity-labels/Deploy-SensitivityLabels.ps1 -ConfigPath ./ws1-purview-sensitivity-labels/config/labels.json -WhatIf
./ws1-purview-sensitivity-labels/Test-SensitivityLabels.ps1 -ConfigPath ./ws1-purview-sensitivity-labels/config/labels.json
```

```bash
# Example: FinOps analysis on the synthetic dataset
python3 ws7-finops-ai/analyze_credits.py ws7-finops-ai/sample-data/copilot_credits_synthetic.csv
```

## What this repository is and is not

| It is | It is not |
|---|---|
| A method and working lab code you can adapt | A compliance certification or legal advice |
| Results from a synthetic lab tenant | A copy of any client deliverable or employer material |
| Explicit about preview vs generally available features | A guarantee that Microsoft menus, rates or licences have not changed since the "verified on" date |

Fast-moving areas (Copilot, Copilot Studio billing, Agent 365, Purview DLP for Copilot) carry a **verified on** date in each README. Check Microsoft Learn before production use.

## Swiss context

Designed for organisations subject to the revised Swiss Federal Act on Data Protection (revDSG / nFADP) and, where relevant, FINMA expectations on outsourcing and operational resilience. The repository gives the technical and architectural perspective only. Interpretation of the law or of contracts belongs to legal counsel or the compliance officer.

## Roadmap

- Same reference use case rebuilt on Microsoft Foundry with Azure AI Search, deployed in Switzerland North, with an automated evaluation pipeline.
- Purview Endpoint DLP for Windows devices, then mobile.
- Data Security Posture Management (DSPM) for AI as the continuous version of the WS3 diagnostic.

## License

MIT, see [LICENSE](LICENSE).
