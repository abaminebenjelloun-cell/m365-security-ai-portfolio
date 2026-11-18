#Requires -Version 7.2
<#
.SYNOPSIS
    Exports DLP policies and rules to JSON so they can be reviewed, diffed and versioned.

.DESCRIPTION
    Read-only. Some DLP capabilities, notably the Microsoft 365 Copilot and Copilot Chat location
    and its preview actions, are configured in the Purview portal first. This script turns what was
    built in the portal into a reviewable artefact (configuration as code, export direction).

    Output goes to ./output, which is ignored by git. Sanitise before sharing: exports from a
    real tenant contain object IDs and names.

.EXAMPLE
    ./01-copilot-readiness/ws2-dlp/Export-DlpPolicyAsCode.ps1 -PolicyName 'Lab - DLP for Copilot'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string[]]$PolicyName
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../../common/M365Lab.Common.ps1')

$export = foreach ($name in $PolicyName) {
    $policy = Get-DlpCompliancePolicy -Identity $name
    $rules = Get-DlpComplianceRule -Policy $name
    [pscustomobject]@{
        Policy = $policy | Select-Object Name, Mode, Comment, Workload, Priority, WhenChanged, *Location*
        Rules  = $rules | Select-Object Name, Priority, Disabled, AccessScope, BlockAccess, BlockAccessScope,
            NotifyUser, NotifyAllowOverride, ContentContainsSensitiveInformation, RestrictAccess,
            GenerateAlert, GenerateIncidentReport, ReportSeverityLevel
    }
}

$dir = Join-Path (Get-Location) 'output'
if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir | Out-Null }
$file = Join-Path $dir ("dlp-export-{0}.json" -f (Get-Date -Format 'yyyyMMdd-HHmm'))
$export | ConvertTo-Json -Depth 10 | Set-Content -Path $file -Encoding utf8
Write-LabLog "Exported $($PolicyName.Count) policy(ies) to $file" 'OK'
