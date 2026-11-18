# WS1: Sensitivity labels

Goal: a simple taxonomy users actually apply, with the most sensitive level technically excluded from Copilot.

**Platform:** Microsoft Purview portal (purview.microsoft.com) and Security & Compliance PowerShell.
**Verified on:** 2026-11-02 against Microsoft Learn (`New-Label` reference).

## Taxonomy

| Level | Encryption | Rights for all employees | Copilot can ground on it | Marking |
|---|---|---|---|---|
| Public | No | n/a | Yes | none |
| Internal (default) | No | n/a | Yes | none |
| Confidential | Yes, admin-defined | Co-author (includes `EXTRACT`) | Yes, for users with access | Footer |
| Secret | Yes, admin-defined | View and edit, no `EXTRACT`, `PRINT`, `FORWARD`, `EXPORT`, `OBJMODEL`, `OWNER` | No | Footer + dynamic watermark (UPN and time), no offline access |

Copilot needs `EXTRACT` to use encrypted content in an answer (lesson L1). The Rights Management owner (whoever applied the label) always keeps full rights, so Copilot still works for that person. Without `EXTRACT`, Secret is excluded structurally; the WS2 DLP rule is a second layer (ADR-002).

## Design choices

- Flat, four levels (ADR-001). Sublabels only if departments later need their own protection.
- Files and emails first. Groups and sites after the oversharing cleanup (WS3).
- One policy publishes all labels, scoped to a mail-enabled pilot group (lessons L2, L4). Group scoping through `-ExchangeLocation` is to be confirmed in the lab; the portal accepts groups directly.
- Offline access 0 days on Secret means "never". The test script reads it back.
- Default label Internal. Moving it to Confidential is a later decision gate.
- Mandatory labelling off at launch, reviewed against adoption metrics.

## Files

| File | Purpose |
|---|---|
| `config/labels.json` | The taxonomy as code (lab domain and pilot group) |
| `Deploy-SensitivityLabels.ps1` | Creates missing labels and the policy. Idempotent, supports `-WhatIf` |
| `Test-SensitivityLabels.ps1` | Reads everything back and checks encryption and the `EXTRACT` right per level |

## Run

```powershell
. ./common/M365Lab.Common.ps1
Connect-LabIPPS -UserPrincipalName admin@contosofiduciaire.onmicrosoft.com
Assert-LabTenant -ExpectedTenantId <lab-tenant-guid> -Service ExchangeOnline

./01-copilot-readiness/ws1-sensitivity-labels/Deploy-SensitivityLabels.ps1 -ConfigPath ./01-copilot-readiness/ws1-sensitivity-labels/config/labels.json -WhatIf
./01-copilot-readiness/ws1-sensitivity-labels/Deploy-SensitivityLabels.ps1 -ConfigPath ./01-copilot-readiness/ws1-sensitivity-labels/config/labels.json
./01-copilot-readiness/ws1-sensitivity-labels/Test-SensitivityLabels.ps1   -ConfigPath ./01-copilot-readiness/ws1-sensitivity-labels/config/labels.json
```

Then in the portal: Purview > Information protection > Policies > Label publishing policies > Lab - Sensitivity labels > Edit. Set the default label for documents and emails to Internal.

## Lab tests

| Test | Expected |
|---|---|
| `pilot.copilot` asks Copilot to summarise a Confidential document they can open | Summary returned |
| Same user asks about a Secret document they can open, **labelled by someone else** | Content not used (whoever applied the encryption keeps full rights, hence another user) |
| Open a Secret document in Word desktop and Word for the web | Dynamic watermark with UPN and time visible |
| Try to print or forward a Secret email | Blocked |
| A user outside the pilot group | Does not see the labels yet |

## Open points for the sponsor

- Enabling co-authoring for encrypted files (one-way, lesson L7).
- Moving the default label to Confidential (phase 2).
- Extending to groups and sites (after WS3).
