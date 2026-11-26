#Requires -Version 7.2
<#
.SYNOPSIS
    Plans or applies one Entitlement Management catalog file and writes a drift report.

.DESCRIPTION
    PRE-CHECK  : validates the file (Test-EmConfig), checks the Graph session and the tenant.
    PLAN       : reads the tenant and reports Create / Update / NoChange / Unmanaged per object. No writes.
    APPLY      : creates or updates only what the plan reported. Never deletes. Honours -WhatIf.
    REPORT     : output/em-<catalog>-<mode>-<timestamp>.json and .md (output/ is never committed).

    -FailOnDrift makes Plan exit with code 2 when anything differs, for a scheduled drift check.

.EXAMPLE
    . ./common/M365Lab.Common.ps1
    Connect-LabGraph -Scopes 'EntitlementManagement.Read.All','Group.Read.All','User.Read.All'
    Assert-LabTenant -ExpectedTenantId <lab-tenant-guid> -Service Graph
    ./07-identity-governance/Deploy-EntitlementManagement.ps1 -ConfigPath ./07-identity-governance/config/catalog-finance.json -Mode Plan

.EXAMPLE
    ./07-identity-governance/Deploy-EntitlementManagement.ps1 -ConfigPath ./07-identity-governance/config/catalog-finance.json -Mode Apply -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$ConfigPath,
    [ValidateSet('Plan', 'Apply')][string]$Mode = 'Plan',
    [string]$ExpectedTenantId,
    [switch]$FailOnDrift
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../common/M365Lab.Common.ps1')
Import-Module (Join-Path $PSScriptRoot 'EntitlementManagement.psm1') -Force

# ---------- PRE-CHECK ----------
$config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
$problems = Test-EmConfig -Config $config
if ($problems.Count) {
    $problems | ForEach-Object { Write-LabLog $_ 'ERROR' }
    throw "Configuration $ConfigPath is not valid."
}
Write-LabLog "Configuration valid: catalog '$($config.catalog.displayName)', $(@($config.accessPackages).Count) access packages" 'OK'

$ctx = Get-MgContext
if (-not $ctx) { throw 'No Microsoft Graph session. Connect first (Connect-LabGraph or Connect-MgGraph).' }
if ($ExpectedTenantId -and $ctx.TenantId -ne $ExpectedTenantId) {
    throw "Connected to tenant $($ctx.TenantId), expected $ExpectedTenantId. Stopping."
}
if ($Mode -eq 'Apply' -and $ctx.Scopes -and ($ctx.Scopes -notcontains 'EntitlementManagement.ReadWrite.All')) {
    Write-LabLog 'Delegated session without EntitlementManagement.ReadWrite.All: writes will fail.' 'WARN'
}

# ---------- PLAN / APPLY ----------
$changes = Sync-EmCatalog -Config $config -Mode $Mode -WhatIf:$WhatIfPreference
$changes | Format-Table Kind, Action, Name, Detail -AutoSize -Wrap | Out-Host

# ---------- REPORT ----------
$outDir = Join-Path (Get-Location) 'output'
if (-not (Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
$slug = ($config.catalog.displayName -replace '[^A-Za-z0-9]+', '-').ToLowerInvariant()
$stem = Join-Path $outDir ('em-{0}-{1}-{2}' -f $slug, $Mode.ToLowerInvariant(), (Get-Date -Format 'yyyyMMdd-HHmmss'))
$changes | ConvertTo-Json -Depth 5 | Set-Content -Path "$stem.json"
$md = @("# Entitlement Management $Mode - $($config.catalog.displayName)", '', '| Kind | Action | Name | Detail |', '|---|---|---|---|')
$md += $changes | ForEach-Object { '| {0} | {1} | {2} | {3} |' -f $_.Kind, $_.Action, $_.Name, ($_.Detail -replace '\|', '/') }
$md | Set-Content -Path "$stem.md"

$drift = @($changes | Where-Object Action -in 'Create', 'Update')
$summary = ($changes | Group-Object Action | ForEach-Object { '{0} {1}' -f $_.Count, $_.Name }) -join ', '
Write-LabLog "$Mode finished: $summary. Report: $stem.md" 'OK'
if ($Mode -eq 'Plan' -and $FailOnDrift -and $drift.Count) {
    Write-LabLog "$($drift.Count) objects differ from the configuration." 'WARN'
    exit 2
}
