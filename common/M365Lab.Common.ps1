#Requires -Version 7.2
<#
.SYNOPSIS
    Shared helpers for the lab scripts in this portfolio.

.DESCRIPTION
    Dot-source this file at the start of a session (from the repository root):
        . ./common/M365Lab.Common.ps1

    It provides:
      - Connect-LabIPPS   : Security & Compliance PowerShell without the WAM broker
      - Connect-LabGraph  : Microsoft Graph with device code flow
      - Assert-LabTenant  : stops if the session is connected to an unexpected tenant
      - Write-LabLog      : timestamped console and file log
      - Export-LabResult  : writes read-back results to ./output with a date stamp

    Why: consultants work across many tenants. Cached broker accounts can silently
    connect a session to the wrong tenant (identity bleed). Every change script
    must therefore confirm the tenant before acting.
#>

Set-StrictMode -Version Latest

$script:LabLogPath = Join-Path -Path (Get-Location) -ChildPath 'output/lab.log'

function Write-LabLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Message,
        [ValidateSet('INFO', 'WARN', 'ERROR', 'OK')][string]$Level = 'INFO'
    )
    $line = '{0} [{1}] {2}' -f (Get-Date -Format 'yyyy-MM-dd HH:mm:ss'), $Level, $Message
    $color = switch ($Level) { 'WARN' { 'Yellow' } 'ERROR' { 'Red' } 'OK' { 'Green' } default { 'Gray' } }
    Write-Host $line -ForegroundColor $color
    $dir = Split-Path -Path $script:LabLogPath -Parent
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    Add-Content -Path $script:LabLogPath -Value $line
}

function Connect-LabIPPS {
    <#
    .SYNOPSIS
        Connects to Security & Compliance PowerShell (Purview) with the WAM broker disabled.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$UserPrincipalName)

    if (-not (Get-Module -ListAvailable -Name ExchangeOnlineManagement)) {
        throw 'ExchangeOnlineManagement module not found. Install it first (see docs/lab-setup.md).'
    }
    if (Get-Module -Name 'Microsoft.Graph.*') {
        Write-LabLog 'Microsoft.Graph modules are loaded in this session. Use a fresh window to avoid authentication library conflicts (lesson L17).' 'WARN'
    }
    Connect-IPPSSession -UserPrincipalName $UserPrincipalName -DisableWAM -ShowBanner:$false
    Write-LabLog "Connected to Security & Compliance PowerShell as $UserPrincipalName" 'OK'
}

function Connect-LabGraph {
    <#
    .SYNOPSIS
        Connects to Microsoft Graph with device code flow and the requested scopes.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string[]]$Scopes)

    if (Get-Module -Name 'ExchangeOnlineManagement') {
        Write-LabLog 'ExchangeOnlineManagement is loaded in this session. Use a fresh window to avoid authentication library conflicts (lesson L17).' 'WARN'
    }
    Connect-MgGraph -Scopes $Scopes -UseDeviceCode -NoWelcome
    $ctx = Get-MgContext
    Write-LabLog ("Connected to Microsoft Graph as {0}, tenant {1}" -f $ctx.Account, $ctx.TenantId) 'OK'
}

function Assert-LabTenant {
    <#
    .SYNOPSIS
        Stops the script if the current connection is not on the expected tenant.
    .PARAMETER ExpectedTenantId
        Tenant ID (GUID) of the lab or target tenant.
    .PARAMETER Service
        Graph or ExchangeOnline (covers Security & Compliance sessions opened with Connect-IPPSSession).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][guid]$ExpectedTenantId,
        [ValidateSet('Graph', 'ExchangeOnline')][string]$Service = 'Graph'
    )

    $actual = $null
    if ($Service -eq 'Graph') {
        $actual = (Get-MgContext).TenantId
    }
    else {
        $info = Get-ConnectionInformation | Select-Object -First 1
        if ($info) { $actual = $info.TenantID }
    }

    if (-not $actual) { throw "No active $Service connection found." }
    if ([guid]$actual -ne $ExpectedTenantId) {
        throw "Connected to tenant $actual but expected $ExpectedTenantId. Stopping before any change."
    }
    Write-LabLog "Tenant check passed ($actual)" 'OK'
}

function Export-LabResult {
    <#
    .SYNOPSIS
        Saves read-back results as CSV and JSON under ./output with a date stamp.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][object[]]$InputObject,
        [Parameter(Mandatory)][string]$Name
    )
    $dir = Join-Path -Path (Get-Location) -ChildPath 'output'
    if (-not (Test-Path $dir)) { New-Item -ItemType Directory -Path $dir -Force | Out-Null }
    $stamp = Get-Date -Format 'yyyyMMdd-HHmm'
    $csv = Join-Path $dir "$Name-$stamp.csv"
    $json = Join-Path $dir "$Name-$stamp.json"
    # UTF-8 with BOM so Excel in a Swiss locale opens accents correctly
    $InputObject | Export-Csv -Path $csv -NoTypeInformation -Encoding utf8BOM
    $InputObject | ConvertTo-Json -Depth 8 | Set-Content -Path $json -Encoding utf8
    Write-LabLog "Results saved to $csv and $json" 'OK'
}
