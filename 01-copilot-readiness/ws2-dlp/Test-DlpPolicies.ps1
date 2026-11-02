#Requires -Version 7.2
<#
.SYNOPSIS
    Reads the lab DLP policies back and checks mode, locations and rules.

.DESCRIPTION
    Read-only. Checks for each expected policy:
      - it exists and is in the expected mode (simulation until a decision gate says otherwise)
      - the expected rules exist and are enabled
      - external sharing rules block access where designed, and the override setting matches
    Results are written to ./output.

.EXAMPLE
    ./01-copilot-readiness/ws2-dlp/Test-DlpPolicies.ps1 -ExternalSharingConfig ./01-copilot-readiness/ws2-dlp/config/dlp-external-sharing.json `
        -CopilotPolicyName 'Lab - DLP for Copilot' -ExpectedCopilotRuleCount 4
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ExternalSharingConfig,
    [string]$CopilotPolicyName = 'Lab - DLP for Copilot',
    [int]$ExpectedCopilotRuleCount = 4
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../../common/M365Lab.Common.ps1')

$config = Get-Content -Path $ExternalSharingConfig -Raw | ConvertFrom-Json
$results = [System.Collections.Generic.List[object]]::new()

function Add-Check($Object, $Check, $Expected, $Actual) {
    $status = if ("$Expected" -eq "$Actual") { 'OK' } else { 'FAIL' }
    $results.Add([pscustomobject]@{ Object = $Object; Check = $Check; Expected = $Expected; Actual = $Actual; Status = $status })
}

# ---------- External sharing policy ----------
$policy = Get-DlpCompliancePolicy -Identity $config.policyName -ErrorAction SilentlyContinue
if (-not $policy) {
    Add-Check $config.policyName 'Exists' $true $false
}
else {
    Add-Check $config.policyName 'Mode' $config.mode $policy.Mode
    $teamsIncluded = [bool]($policy.TeamsLocation)
    Add-Check $config.policyName 'Teams location excluded (lesson L8)' $false $teamsIncluded

    $rules = @(Get-DlpComplianceRule -Policy $config.policyName)
    foreach ($expected in $config.rules) {
        $actual = $rules | Where-Object Name -eq $expected.name
        if (-not $actual) { Add-Check $expected.name 'Exists' $true $false; continue }
        Add-Check $expected.name 'Enabled' $true (-not $actual.Disabled)
        Add-Check $expected.name 'BlockAccess' ([bool]$expected.blockAccess) ([bool]$actual.BlockAccess)
        if ($expected.blockAccess) {
            $expectedOverride = if ($expected.override -eq 'none') { '' } else { $expected.override }
            Add-Check $expected.name 'Override' $expectedOverride ("$($actual.NotifyAllowOverride)".Trim())
        }
    }
}

# ---------- Copilot DLP policy (configured in the portal, see copilot-dlp-runbook.md) ----------
$copilot = Get-DlpCompliancePolicy -Identity $CopilotPolicyName -ErrorAction SilentlyContinue
if (-not $copilot) {
    Add-Check $CopilotPolicyName 'Exists' $true $false
}
else {
    Add-Check $CopilotPolicyName 'Mode' 'TestWithNotifications' $copilot.Mode
    $copilotRules = @(Get-DlpComplianceRule -Policy $CopilotPolicyName)
    Add-Check $CopilotPolicyName 'Rule count' $ExpectedCopilotRuleCount $copilotRules.Count
    foreach ($r in $copilotRules) {
        Add-Check $r.Name 'Enabled' $true (-not $r.Disabled)
    }
}

$results | Format-Table -AutoSize
Export-LabResult -InputObject $results -Name 'ws2-dlp-readback'

$failed = @($results | Where-Object Status -eq 'FAIL').Count
if ($failed -gt 0) { Write-LabLog "$failed check(s) failed" 'ERROR' } else { Write-LabLog 'All DLP checks passed' 'OK' }
