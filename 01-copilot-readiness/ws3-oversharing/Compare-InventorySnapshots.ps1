#Requires -Version 7.2
<#
.SYNOPSIS
    Compares two inventory snapshots and reports remediation progress.

.DESCRIPTION
    Offline, no tenant connection needed. Takes two CSV files produced by
    Get-SharePointInventory.ps1 (before and after) and reports:
      - sites removed and sites added
      - sites whose sharing capability changed
      - exposure flags before vs after (anonymous, external, inactive, no owner, no label)
      - storage change

    Sites added or changed by the remediation team itself (for example admin groups added as
    site collection administrators) should be listed in -ExcludeUrlPattern so they do not
    distort the client's cleanup metrics.

.EXAMPLE
    ./01-copilot-readiness/ws3-oversharing/Compare-InventorySnapshots.ps1 `
        -Before ./01-copilot-readiness/ws3-oversharing/sample-data/inventory_before.csv `
        -After  ./01-copilot-readiness/ws3-oversharing/sample-data/inventory_after.csv
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$Before,
    [Parameter(Mandatory)][string]$After,
    [string]$ExcludeUrlPattern
)

$ErrorActionPreference = 'Stop'

$old = Import-Csv -Path $Before
$new = Import-Csv -Path $After
if ($ExcludeUrlPattern) {
    $old = $old | Where-Object Url -notmatch $ExcludeUrlPattern
    $new = $new | Where-Object Url -notmatch $ExcludeUrlPattern
}

$oldByUrl = @{}; $old | ForEach-Object { $oldByUrl[$_.Url] = $_ }
$newByUrl = @{}; $new | ForEach-Object { $newByUrl[$_.Url] = $_ }

$removed = $old | Where-Object { -not $newByUrl.ContainsKey($_.Url) }
$added = $new | Where-Object { -not $oldByUrl.ContainsKey($_.Url) }
$sharingChanged = foreach ($n in $new) {
    if ($oldByUrl.ContainsKey($n.Url) -and $oldByUrl[$n.Url].SharingCapability -ne $n.SharingCapability) {
        [pscustomobject]@{ Url = $n.Url; Before = $oldByUrl[$n.Url].SharingCapability; After = $n.SharingCapability }
    }
}

function Get-FlagCount($rows, $flag) { @($rows | Where-Object { $_.$flag -eq 'True' }).Count }

$flags = 'AnonymousLinksAllowed', 'ExternalSharing', 'Inactive', 'NoOwner', 'NoSensitivityLabel'
$flagTable = foreach ($f in $flags) {
    $b = Get-FlagCount $old $f
    $a = Get-FlagCount $new $f
    [pscustomobject]@{ Flag = $f; Before = $b; After = $a; Change = $a - $b }
}

$storageBefore = [math]::Round((($old | Measure-Object -Property StorageMB -Sum).Sum) / 1024, 1)
$storageAfter = [math]::Round((($new | Measure-Object -Property StorageMB -Sum).Sum) / 1024, 1)

Write-Host "`n=== Inventory delta ===" -ForegroundColor Cyan
Write-Host ("Sites before: {0}  after: {1}  removed: {2}  added: {3}" -f $old.Count, $new.Count, @($removed).Count, @($added).Count)
Write-Host ("Storage GB before: {0}  after: {1}" -f $storageBefore, $storageAfter)
Write-Host "`nExposure flags" -ForegroundColor Cyan
$flagTable | Format-Table -AutoSize
if ($sharingChanged) { Write-Host 'Sharing capability changed' -ForegroundColor Cyan; $sharingChanged | Format-Table -AutoSize }
if ($removed) { Write-Host 'Removed' -ForegroundColor Cyan; $removed | Select-Object Url, Type | Format-Table -AutoSize }
if ($added) { Write-Host 'Added' -ForegroundColor Cyan; $added | Select-Object Url, Type | Format-Table -AutoSize }
