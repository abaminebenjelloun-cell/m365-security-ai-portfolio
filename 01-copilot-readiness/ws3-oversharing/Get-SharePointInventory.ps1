#Requires -Version 7.2
<#
.SYNOPSIS
    Inventories SharePoint sites and OneDrive accounts with exposure flags for Copilot readiness.

.DESCRIPTION
    Read-only. For every site it collects owner, template, Teams connection, storage, last activity,
    sharing capability and sensitivity label, then adds simple exposure flags:

      AnonymousLinksAllowed : site allows "Anyone" links
      ExternalSharing       : site allows sharing with guests
      Inactive              : no content change for more than -InactiveDays
      NoOwner               : no owner recorded (non group-connected sites)
      NoSensitivityLabel    : no container label on the site

    The output is the baseline for remediation and for the delta report
    (Compare-InventorySnapshots.ps1). Permission-level oversharing (for example
    "Everyone except external users" on a site) is covered by the SharePoint Advanced Management
    data access governance reports, referenced in the README.

    Requires: Microsoft.Online.SharePoint.PowerShell, SharePoint Administrator role,
    a session opened with Connect-SPOService.

.EXAMPLE
    Connect-SPOService -Url https://contosofiduciaire-admin.sharepoint.com -UseSystemBrowser $true
    ./01-copilot-readiness/ws3-oversharing/Get-SharePointInventory.ps1 -InactiveDays 180
#>
[CmdletBinding()]
param(
    [int]$InactiveDays = 180,
    [switch]$IncludeOneDrive
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../../common/M365Lab.Common.ps1')

if (-not (Get-Command Get-SPOSite -ErrorAction SilentlyContinue)) {
    throw 'Get-SPOSite not available. Install Microsoft.Online.SharePoint.PowerShell and run Connect-SPOService.'
}

Write-LabLog 'Reading sites (this can take several minutes on large tenants)'
$sites = Get-SPOSite -Limit All -IncludePersonalSite:$IncludeOneDrive.IsPresent
$cutoff = (Get-Date).AddDays(-$InactiveDays)

$inventory = foreach ($s in $sites) {
    $isOneDrive = $s.Url -match '-my\.sharepoint\.com/personal/'
    [pscustomobject]@{
        Url                   = $s.Url
        Title                 = $s.Title
        Type                  = if ($isOneDrive) { 'OneDrive' } elseif ($s.IsTeamsConnected) { 'Teams site' } elseif ($s.GroupId -and $s.GroupId -ne [guid]::Empty) { 'Group site' } else { 'Site' }
        Template              = $s.Template
        Owner                 = $s.Owner
        StorageMB             = $s.StorageUsageCurrent
        LastContentModified   = $s.LastContentModifiedDate
        SharingCapability     = $s.SharingCapability
        SensitivityLabel      = $s.SensitivityLabel
        LockState             = $s.LockState
        AnonymousLinksAllowed = ($s.SharingCapability -eq 'ExternalUserAndGuestSharing')
        ExternalSharing       = ($s.SharingCapability -ne 'Disabled')
        Inactive              = ($s.LastContentModifiedDate -lt $cutoff)
        NoOwner               = (-not $isOneDrive) -and ([string]::IsNullOrWhiteSpace($s.Owner)) -and (-not $s.GroupId -or $s.GroupId -eq [guid]::Empty)
        NoSensitivityLabel    = [string]::IsNullOrWhiteSpace($s.SensitivityLabel)
    }
}

$summary = [pscustomobject]@{
    Sites                 = @($inventory | Where-Object Type -ne 'OneDrive').Count
    OneDriveAccounts      = @($inventory | Where-Object Type -eq 'OneDrive').Count
    TotalStorageGB        = [math]::Round((($inventory | Measure-Object StorageMB -Sum).Sum) / 1024, 1)
    AnonymousLinksAllowed = @($inventory | Where-Object AnonymousLinksAllowed).Count
    ExternalSharing       = @($inventory | Where-Object ExternalSharing).Count
    Inactive              = @($inventory | Where-Object Inactive).Count
    NoOwner               = @($inventory | Where-Object NoOwner).Count
    NoSensitivityLabel    = @($inventory | Where-Object NoSensitivityLabel).Count
}

$summary | Format-List
Export-LabResult -InputObject $inventory -Name 'ws3-inventory'
