# WS2: Data Loss Prevention

**Goal:** stop sensitive content from leaving through Copilot answers, web searches or external sharing, with enforcement decided on real data.

**Platform:** Microsoft Purview portal and Security & Compliance PowerShell.
**Verified on:** 2026-11-02 against Microsoft Learn (DLP for Copilot location, `New-DlpCompliancePolicy`, `New-DlpComplianceRule`).

## Two policies, two purposes

| Policy | Locations | Built with | Mode at start |
|---|---|---|---|
| `Blueprint - DLP for Copilot` | Microsoft 365 Copilot and Copilot Chat only | Purview portal (see [runbook](copilot-dlp-runbook.md)), exported as code | Simulation |
| `Blueprint - DLP external sharing` | Exchange, SharePoint, OneDrive (Teams excluded) | `Deploy-ExternalSharingDlp.ps1` | Simulation |

### DLP for Copilot

| Rule | What it prevents | Status |
|---|---|---|
| Secret excluded | Copilot using Secret content | Available |
| Swiss sensitive data, no web search | AHV, IBAN or card data in a prompt reaching a web search | Check availability |
| External email excluded | Copilot grounding on email from external senders | **Preview** |
| Confidential measurement | Nothing yet, it measures | Decision gate |

### External sharing

| Rule | Condition | Action |
|---|---|---|
| Secret | Label Secret, shared outside the organisation | Block, no override |
| Confidential | Label Confidential, shared outside | Block, override with business justification |
| Swiss sensitive data | AHV, IBAN, credit card shared outside | Incident report only |

## Scoping and its limits

- Exchange and OneDrive are scoped to the pilot group.
- **SharePoint applies to all sites** and cannot be scoped to users (lesson L9). That is why everything starts in simulation.
- **Teams is excluded**: the label condition is not available with the Teams location (lesson L8). Cover Teams in a separate policy based on sensitive information types if needed.

## Files

| File | Purpose |
|---|---|
| `config/dlp-external-sharing.json` | External sharing policy as code |
| `Deploy-ExternalSharingDlp.ps1` | Creates the policy and rules in simulation, rolls back the policy if a rule fails |
| `copilot-dlp-runbook.md` | Portal steps for the Copilot location, preview flags |
| `Export-DlpPolicyAsCode.ps1` | Exports any DLP policy and its rules to JSON for review and diff |
| `Test-DlpPolicies.ps1` | Reads both policies back: mode, rules, block and override settings |
| `test-matrix.md` | Functional tests for the pilot, with simulation vs enforced expectations |

## Run

```powershell
. ./common/Blueprint.Common.ps1
Connect-BlueprintIPPS -UserPrincipalName admin@contosofiduciaire.onmicrosoft.com
Assert-BlueprintTenant -ExpectedTenantId <lab-tenant-guid> -Service ExchangeOnline

./ws2-purview-dlp/Deploy-ExternalSharingDlp.ps1 -ConfigPath ./ws2-purview-dlp/config/dlp-external-sharing.json -WhatIf
./ws2-purview-dlp/Deploy-ExternalSharingDlp.ps1 -ConfigPath ./ws2-purview-dlp/config/dlp-external-sharing.json
# Build the Copilot policy in the portal (runbook), then:
./ws2-purview-dlp/Test-DlpPolicies.ps1 -ExternalSharingConfig ./ws2-purview-dlp/config/dlp-external-sharing.json
```

Sensitive information type names differ slightly between tenants and languages. The deploy script checks each name with `Get-DlpSensitiveInformationType` before creating anything.

## Next steps (roadmap)

- Endpoint DLP on Windows devices (copy to USB, upload to unsanctioned AI sites), then mobile.
- Data Security Posture Management for AI to monitor prompts and responses continuously.
