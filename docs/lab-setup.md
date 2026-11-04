# Lab setup

Everything in this repository is designed for a personal lab tenant with synthetic data. The README status table states what has and has not been run. Never run these scripts first on a production tenant.

## 1. Tenant

- A Microsoft 365 developer or trial tenant with E5 (or E5 Compliance) to unlock DLP for Copilot and auto-labelling.
- At least one Microsoft 365 Copilot licence for testing grounding behaviour.
- A Power Platform environment for Copilot Studio (the default environment is enough for the lab).

## 2. Fictional organisation

**Contoso Fiduciaire SA** (fictional), a Swiss fiduciary with three departments.

| Object | Lab value |
|---|---|
| Users | `alice` (Finance), `bruno` (HR), `chloe` (Partner), `pilot.copilot` (test account) |
| Pilot group | `SG-Pilot-Copilot` (mail-enabled security group, ring 0) |
| Sites | `Finance` (members only), `HR` (members only), `All-Company` (deliberately overshared, with a file containing synthetic AHV and IBAN numbers), `Partners` (one anonymous link, deliberately) |

Synthetic identifiers only. Use test values that match the format of sensitive information types but belong to nobody.

## 3. Tools

| Tool | Version used | Install |
|---|---|---|
| PowerShell | 7.4+ | https://learn.microsoft.com/powershell/scripting/install/installing-powershell |
| ExchangeOnlineManagement | 3.x | `Install-Module ExchangeOnlineManagement` |
| Microsoft.Graph | 2.x | `Install-Module Microsoft.Graph` |
| Microsoft.Online.SharePoint.PowerShell | latest known-good | `Install-Module Microsoft.Online.SharePoint.PowerShell` |
| Microsoft.PowerApps.Administration.PowerShell | 2.x | `Install-Module Microsoft.PowerApps.Administration.PowerShell` |
| Python | 3.10+ | for WS4 and WS7 analysis scripts (standard library only) |

## 4. Connection rules

Use the helpers in `common/M365Lab.Common.ps1`:

- Device code or browser flow, no cached broker account.
- Print the tenant ID after connecting and compare it with the expected lab tenant before any change.
- One module family per PowerShell window (lesson L17).
