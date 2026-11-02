#Requires -Version 7.2
<#
.SYNOPSIS
    Takes a monthly Microsoft Secure Score snapshot and plans the next improvement wave.

.DESCRIPTION
    Read-only. Reads the latest Secure Score and every control profile through Microsoft Graph,
    joins them, and exports one line per recommendation with:
      current points, max points, gap, user impact, implementation cost, service, and the state
      set by an administrator (for example risk accepted or resolved through a third party).

    The gap list sorted by "points per user impact" is the input for the next wave.

    Requires Microsoft.Graph.Security and the SecurityEvents.Read.All permission.

.EXAMPLE
    . ./common/M365Lab.Common.ps1
    Connect-LabGraph -Scopes 'SecurityEvents.Read.All'
    Assert-LabTenant -ExpectedTenantId <lab-tenant-guid>
    ./04-secure-score-governance/Get-SecureScoreSnapshot.ps1 -TargetPercent 70
#>
[CmdletBinding()]
param(
    [ValidateRange(1, 100)][int]$TargetPercent = 70
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../common/M365Lab.Common.ps1')

$score = Get-MgSecuritySecureScore -Top 1
$profiles = Get-MgSecuritySecureScoreControlProfile -All

$current = [math]::Round($score.CurrentScore, 1)
$max = [math]::Round($score.MaxScore, 1)
$percent = if ($max) { [math]::Round(100 * $current / $max, 1) } else { 0 }
$pointsToTarget = [math]::Max(0, [math]::Round(($TargetPercent / 100) * $max - $current, 1))

Write-LabLog "Secure Score $current / $max ($percent%). Target $TargetPercent% needs $pointsToTarget more points."

$scoreByControl = @{}
foreach ($c in $score.ControlScores) { $scoreByControl[$c.ControlName] = [double]$c.Score }

$rows = foreach ($p in $profiles) {
    $earned = if ($scoreByControl.ContainsKey($p.Id)) { $scoreByControl[$p.Id] } else { 0 }
    $latestState = $p.ControlStateUpdates | Sort-Object UpdatedDateTime -Descending | Select-Object -First 1
    [pscustomobject]@{
        Control            = $p.Id
        Title              = $p.Title
        Service            = $p.Service
        Earned             = $earned
        MaxScore           = $p.MaxScore
        Gap                = [math]::Round($p.MaxScore - $earned, 2)
        UserImpact         = $p.UserImpact
        ImplementationCost = $p.ImplementationCost
        AdminState         = if ($latestState) { $latestState.State } else { 'Default' }
        AdminStateReason   = if ($latestState) { $latestState.Comment } else { '' }
        Deprecated         = $p.Deprecated
    }
}

$open = $rows | Where-Object { $_.Gap -gt 0 -and -not $_.Deprecated -and $_.AdminState -eq 'Default' }

# Wave candidates: most points for the least user impact first
$impactRank = @{ 'Low' = 1; 'Moderate' = 2; 'High' = 3 }
$plan = $open | Sort-Object @{ Expression = { $impactRank["$($_.UserImpact)"] } }, @{ Expression = 'Gap'; Descending = $true }

Write-Host "`nTop 15 candidates for the next wave" -ForegroundColor Cyan
$plan | Select-Object -First 15 Title, Service, Gap, UserImpact, ImplementationCost | Format-Table -AutoSize

Export-LabResult -InputObject $rows -Name 'ws8-securescore-snapshot'
