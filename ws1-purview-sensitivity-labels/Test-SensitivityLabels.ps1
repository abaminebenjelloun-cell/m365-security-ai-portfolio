#Requires -Version 7.2
<#
.SYNOPSIS
    Reads the label taxonomy back from the tenant and compares it with the configuration.

.DESCRIPTION
    Read-only. For each label in the configuration it checks:
      - the label exists and has the expected display name and priority
      - encryption is on or off as designed
      - the EXTRACT right is present (Copilot grounding allowed) or absent (Copilot grounding blocked)
    and checks that the label policy publishes every label.

    Output: a table on screen and a dated CSV/JSON in ./output (never committed).

    Why: a setting only counts once it has been read back from the tenant (lesson L25).
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$ConfigPath
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../common/Blueprint.Common.ps1')

$config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json
$results = [System.Collections.Generic.List[object]]::new()

foreach ($expected in $config.labels) {
    $actual = Get-Label -Identity $expected.name -ErrorAction SilentlyContinue

    if (-not $actual) {
        $results.Add([pscustomobject]@{ Label = $expected.name; Check = 'Exists'; Expected = 'Yes'; Actual = 'No'; Status = 'FAIL' })
        continue
    }

    $results.Add([pscustomobject]@{ Label = $expected.name; Check = 'DisplayName'; Expected = $expected.displayName; Actual = $actual.DisplayName
        Status = if ($actual.DisplayName -eq $expected.displayName) { 'OK' } else { 'FAIL' } })

    $results.Add([pscustomobject]@{ Label = $expected.name; Check = 'Priority'; Expected = $expected.priority; Actual = $actual.Priority
        Status = if ([int]$actual.Priority -eq [int]$expected.priority) { 'OK' } else { 'FAIL' } })

    # LabelActions holds the encryption, marking and watermark settings as JSON strings
    $actionsText = ($actual.LabelActions | Out-String)
    $hasEncryption = $actionsText -match '"Type"\s*:\s*"encrypt"'
    $wantEncryption = [bool]$expected.encryption

    $results.Add([pscustomobject]@{ Label = $expected.name; Check = 'Encryption'; Expected = $wantEncryption; Actual = $hasEncryption
        Status = if ($hasEncryption -eq $wantEncryption) { 'OK' } else { 'FAIL' } })

    if ($wantEncryption) {
        $hasExtract = $actionsText -match '\bEXTRACT\b'
        $wantExtract = ($expected.copilotGrounding -eq 'allowed')
        $results.Add([pscustomobject]@{ Label = $expected.name; Check = 'EXTRACT right (Copilot grounding)'; Expected = $wantExtract; Actual = $hasExtract
            Status = if ($hasExtract -eq $wantExtract) { 'OK' } else { 'FAIL' } })
    }
}

# Label policy publishes all labels (lesson L2)
$policy = Get-LabelPolicy -Identity $config.policyName -ErrorAction SilentlyContinue
if ($policy) {
    $published = @($policy.Labels)
    foreach ($name in $config.labels.name) {
        $isPublished = [bool]($published | Where-Object { $_ -match [regex]::Escape($name) })
        $results.Add([pscustomobject]@{ Label = $name; Check = 'Published in policy'; Expected = $true; Actual = $isPublished
            Status = if ($isPublished) { 'OK' } else { 'FAIL' } })
    }
}
else {
    $results.Add([pscustomobject]@{ Label = '(policy)'; Check = 'Label policy exists'; Expected = $config.policyName; Actual = 'missing'; Status = 'FAIL' })
}

$results | Format-Table -AutoSize
Export-BlueprintResult -InputObject $results -Name 'ws1-label-readback'

$failed = @($results | Where-Object Status -eq 'FAIL').Count
if ($failed -gt 0) { Write-BlueprintLog "$failed check(s) failed" 'ERROR' } else { Write-BlueprintLog 'All label checks passed' 'OK' }
