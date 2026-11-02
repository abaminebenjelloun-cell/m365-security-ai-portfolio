#Requires -Version 5.1
<#
.SYNOPSIS
    Reads the Power Platform data policies back and checks that the Copilot Studio policy blocks
    the expected connectors and keeps the core Microsoft 365 connectors in the business group.

.DESCRIPTION
    Read-only. Uses Get-DlpPolicy from Microsoft.PowerApps.Administration.PowerShell.
    Requires the Power Platform administrator role and a session opened with Add-PowerAppsAccount.

    Connector names are matched case-insensitively on display name. The output shape of
    Get-DlpPolicy has changed across module versions; the script handles both a 'value' wrapper
    and a direct list, and tells you if it cannot find connector groups at all.

.EXAMPLE
    Add-PowerAppsAccount
    ./02-agent-governance/Test-PowerPlatformDataPolicy.ps1 -ConfigPath ./02-agent-governance/config/copilot-studio-data-policy.json
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ConfigPath
)

$ErrorActionPreference = 'Stop'

if (-not (Get-Command Get-DlpPolicy -ErrorAction SilentlyContinue)) {
    throw 'Get-DlpPolicy not found. Install Microsoft.PowerApps.Administration.PowerShell and run Add-PowerAppsAccount.'
}

$config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

$raw = Get-DlpPolicy
$policies = if ($raw.PSObject.Properties.Name -contains 'value') { $raw.value } else { $raw }
$policy = $policies | Where-Object { $_.displayName -eq $config.policyDisplayName } | Select-Object -First 1

if (-not $policy) {
    Write-Host "FAIL  Data policy '$($config.policyDisplayName)' not found. Policies present:" -ForegroundColor Red
    $policies | ForEach-Object { Write-Host "      - $($_.displayName)" }
    exit 1
}

if (-not ($policy.PSObject.Properties.Name -contains 'connectorGroups')) {
    throw 'connectorGroups not found on the policy object. Check the module version and inspect Get-DlpPolicy output manually.'
}

function Get-GroupConnectorNames([object]$Policy, [string]$Classification) {
    $group = $Policy.connectorGroups | Where-Object { $_.classification -eq $Classification }
    if ($group) { @($group.connectors | ForEach-Object { $_.name }) } else { @() }
}

$blocked = Get-GroupConnectorNames $policy 'Blocked'
$business = Get-GroupConnectorNames $policy 'Confidential'   # 'Confidential' is the API name of the Business group

$results = @()
foreach ($name in $config.mustBeBlocked) {
    $ok = [bool]($blocked | Where-Object { $_ -ieq $name })
    $results += [pscustomobject]@{ Connector = $name; Expected = 'Blocked'; Status = if ($ok) { 'OK' } else { 'FAIL' } }
}
foreach ($name in $config.mustBeBusiness) {
    $ok = [bool]($business | Where-Object { $_ -ieq $name })
    $results += [pscustomobject]@{ Connector = $name; Expected = 'Business'; Status = if ($ok) { 'OK' } else { 'FAIL' } }
}

$results | Format-Table -AutoSize
$failed = @($results | Where-Object Status -eq 'FAIL').Count
if ($failed -gt 0) {
    Write-Host "$failed check(s) failed. Connector display names change over time: compare with the portal before changing the policy." -ForegroundColor Yellow
}
else {
    Write-Host 'All data policy checks passed' -ForegroundColor Green
}
