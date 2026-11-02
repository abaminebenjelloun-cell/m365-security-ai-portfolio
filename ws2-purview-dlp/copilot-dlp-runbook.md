# Runbook: DLP for Microsoft 365 Copilot and Copilot Chat

**Platform:** Microsoft Purview portal > Data loss prevention > Policies > Create policy > **Custom**.
**Verified on:** 2026-11-02 against Microsoft Learn ("Learn about the Microsoft 365 Copilot and Copilot Chat policy location").

The Copilot location is configured in the portal, then exported for review with `Export-DlpPolicyAsCode.ps1`. Several actions are preview and the PowerShell surface for them changes, so the portal is the reliable path today.

## Rules to know before you start

- The location **Microsoft 365 Copilot and Copilot Chat** is only available in the **Custom** template, and selecting it disables every other location (lesson L10).
- A **sensitivity label condition and a sensitive information type condition cannot share a rule**. One rule per condition type (lesson L11).
- Changes can take **up to four hours** to apply in Copilot (lesson L12).

## Policy

| Setting | Value |
|---|---|
| Name | `Blueprint - DLP for Copilot` |
| Template | Custom |
| Location | Microsoft 365 Copilot and Copilot Chat only |
| Scope | Pilot group (ring 0) |
| Mode | Run the policy in simulation mode, show policy tips |

## Rules

| # | Rule name | Condition | Action | Status |
|---|---|---|---|---|
| 1 | Secret - excluded from Copilot | Content contains > Sensitivity labels > **Secret** | Prevent Copilot from processing content | Available. Second layer behind the missing `EXTRACT` right (ADR-002) |
| 2 | Swiss sensitive data - no web search | Content contains > Sensitive information types > AHV, IBAN, credit card | Prevent Copilot from processing content > **Performing web searches** | Check tenant availability |
| 3 | External email - excluded from grounding | Email is received from > **External users** | Prevent Copilot from processing content | **Preview.** Evaluates sender domain metadata only |
| 4 | Confidential - measurement | Content contains > Sensitivity labels > **Confidential** | Prevent Copilot from processing content | **Measurement only**: stays in simulation until the decision gate (ADR-003) |

Optional, **preview**: a rule that blocks **prompts** containing sensitive information types (Prevent Copilot from processing content > Processing prompts). Check rollout to the tenant first. In Word, Excel and PowerPoint the block message may not say a policy caused it, so brief the help desk.

## After saving

1. Wait up to four hours.
2. Run the test matrix (`test-matrix.md`) with `pilot.copilot`.
3. Export for review:
   ```powershell
   ./ws2-purview-dlp/Export-DlpPolicyAsCode.ps1 -PolicyName 'Blueprint - DLP for Copilot'
   ```
4. Read back with `Test-DlpPolicies.ps1`.
5. After two to four weeks of simulation, bring the volumes to the decision gate.
