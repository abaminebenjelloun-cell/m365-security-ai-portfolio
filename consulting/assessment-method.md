# Assessment method: Microsoft 365 flash assessment

A short, repeatable Microsoft 365 security and governance assessment, used as the entry point of an engagement. Built as a productised offer: same structure for every client, reusable templates, a quality-control layer, and a guide so other consultants deliver it without the author.

Track record: first version built around 148 controls aligned with the CIS Microsoft 365 Foundations Benchmark, then industrialised with reusable templates, Copilot-assisted filling and a written guide so colleagues deliver it independently. Delivered to several clients (association, SME, public sector).

> This page describes the method only. Templates, scoring workbooks and client deliverables built with an employer are not part of this repository.

## 1. Inputs

| Input | Purpose |
|---|---|
| Health check export from a Microsoft 365 posture tool | Tenant configuration against the tool's own policies |
| Reconciliation against the **CIS Microsoft 365 Foundations Benchmark** | Mapping to an external, recognised baseline |
| Microsoft Secure Score (read through Microsoft Graph) | Microsoft's own view, kept separate from the CIS view |

**Rule:** one primary data source per assessment, every figure in the deliverable traceable to it. If a workload has not been imported yet, wait for it rather than mix manual observations into the score.

## 2. Structure

Pillars: Security and Identity, Entra applications, Exchange, SharePoint and OneDrive, Teams, Devices, Licences, Identity Governance, Copilot readiness.

Statuses: Compliant, Partially compliant, Not compliant, Informational.

| Priority | Meaning | Example |
|---|---|---|
| P1 | Fix within 30 days, exposure is real | Global administrators without MFA |
| P2 | Fix this quarter | Permanent admin role assignments where PIM is licensed |
| P3 | Plan | Policies covered by an equivalent control under another name |
| P4 | Nice to have | Cosmetic or low-risk drift |

## 3. Scoring

Unified score on a 2 / 1 / 0 scale (Compliant / Partial / Not compliant), Informational excluded. The tool's native score is reported as is, never recalculated, so the client can compare over time.

## 4. Deliverables

1. Workbook: read-me, hidden data sheet, dashboard, CIS comparison, health check, action plan, and an affected accounts sheet (named users, apps or sites per finding) so each finding is actionable.
2. Executive deck (about six slides): score, pillar view, top 5 risks, action plan, next steps. Speaker notes point to where each figure lives in the workbook.

## 5. Quality control

- Control totals from the exports are compared automatically with the counts in the workbook. Any mismatch shows CHECK instead of OK.
- Accounts and applications created by the assessment tool itself are excluded from findings (they would otherwise appear as risky service principals).
- Every number in the deck is checked against the workbook before delivery.

## 6. Copilot in the delivery

Microsoft 365 Copilot extracts counts and lists from the exports into the workbook. The rule:

> **Copilot extracts, Excel calculates, the consultant decides.**

Copilot never assigns a priority or writes a conclusion on its own. The assessment stays fast without delegating judgment.

## 7. Link to the rest of the portfolio

| Assessment finding | Workstream |
|---|---|
| Users without MFA, permanent admin roles | WS8 Secure Score governance |
| Anonymous or guest sharing, sites without expiration | WS3 oversharing |
| Applications with broad ReadWrite permissions | WS4 agents and connectors |
| No labels, no DLP | WS1, WS2 |
