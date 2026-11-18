#Requires -Version 7.2
<#
.SYNOPSIS
    Creates the external sharing DLP policy (Exchange, SharePoint, OneDrive) in simulation mode.

.DESCRIPTION
    PRE-CHECK  : tenant check, policy name not already used, labels and SIT names resolvable.
    ACTION     : one policy in TestWithNotifications mode, three rules:
                   1. Secret shared outside the organisation  -> block, no override
                   2. Confidential shared outside             -> block, override with business justification
                   3. Swiss sensitive data shared outside     -> incident report only, no block
                 If a rule fails, the policy just created is removed (rollback),
                 so no orphaned policy is left behind (lesson L14 applies to DLP too).
    POST-VERIFY: run Test-DlpPolicies.ps1.

    Scoping (ring 0):
      - Exchange : senders who are members of the pilot group
      - OneDrive : OneDrive accounts of pilot group members
      - SharePoint: All sites. The SharePoint location cannot be scoped to users (lesson L9),
                    which is why the policy starts in simulation.

    Teams is intentionally not included: the sensitivity label condition is not available
    when the Teams chat and channel location is selected (lesson L8).

.EXAMPLE
    ./01-copilot-readiness/ws2-dlp/Deploy-ExternalSharingDlp.ps1 -ConfigPath ./01-copilot-readiness/ws2-dlp/config/dlp-external-sharing.json -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$ConfigPath
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../../common/M365Lab.Common.ps1')

$config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

# ---------- PRE-CHECK ----------
if (Get-DlpCompliancePolicy -Identity $config.policyName -ErrorAction SilentlyContinue) {
    throw "Policy '$($config.policyName)' already exists. Use Test-DlpPolicies.ps1 to read it back."
}

foreach ($rule in $config.rules) {
    if ($rule.PSObject.Properties.Name -contains 'label' -and $rule.label) {
        if (-not (Get-Label -Identity $rule.label -ErrorAction SilentlyContinue)) {
            throw "Label '$($rule.label)' not found. Deploy WS1 first."
        }
    }
    if ($rule.PSObject.Properties.Name -contains 'sensitiveInfoTypes') {
        foreach ($sit in $rule.sensitiveInfoTypes) {
            if (-not (Get-DlpSensitiveInformationType -Identity $sit -ErrorAction SilentlyContinue)) {
                throw "Sensitive information type '$sit' not found. Check the exact name with Get-DlpSensitiveInformationType."
            }
        }
    }
}
Write-LabLog 'Pre-checks passed'

# ---------- ACTION ----------
if (-not $PSCmdlet.ShouldProcess($config.policyName, 'Create DLP policy and rules in simulation mode')) { return }

New-DlpCompliancePolicy -Name $config.policyName `
    -Comment 'Copilot Security Lab - external sharing. Created in simulation mode.' `
    -ExchangeLocation All -ExchangeSenderMemberOf $config.pilotGroup `
    -SharePointLocation All `
    -OneDriveLocation All -OneDriveSharedByMemberOf $config.pilotGroup `
    -Mode $config.mode | Out-Null
Write-LabLog "Created policy '$($config.policyName)' in mode $($config.mode)" 'OK'

try {
    foreach ($rule in $config.rules) {
        $ruleParams = @{
            Name        = $rule.name
            Policy      = $config.policyName
            AccessScope = 'NotInOrganization'
        }

        if ($rule.PSObject.Properties.Name -contains 'label' -and $rule.label) {
            $ruleParams.ContentContainsSensitiveInformation = @(
                @{ operator = 'And'; groups = @(
                        @{ operator = 'Or'; name = 'Default'; labels = @(@{ name = $rule.label; type = 'Sensitivity' }) }
                    ) }
            )
        }
        else {
            $ruleParams.ContentContainsSensitiveInformation = @(
                $rule.sensitiveInfoTypes | ForEach-Object { @{ Name = $_; minCount = '1' } }
            )
        }

        if ($rule.blockAccess) {
            $ruleParams.BlockAccess      = $true
            $ruleParams.BlockAccessScope = 'PerUser'      # blocks external users only
            $ruleParams.NotifyUser       = 'Owner'
            if ($rule.override -ne 'none') {
                $ruleParams.NotifyAllowOverride = $rule.override
            }
        }
        else {
            $ruleParams.GenerateIncidentReport = $config.alertRecipient
        }

        New-DlpComplianceRule @ruleParams | Out-Null
        Write-LabLog "Created rule '$($rule.name)'" 'OK'
    }
}
catch {
    Write-LabLog "Rule creation failed: $($_.Exception.Message). Rolling back the policy." 'ERROR'
    Remove-DlpCompliancePolicy -Identity $config.policyName -Confirm:$false
    throw
}

Write-LabLog 'Done. Run Test-DlpPolicies.ps1, then review simulation results in Purview > Data loss prevention > Policies before any enforcement decision.'
