#Requires -Version 7.2
<#
.SYNOPSIS
    Creates the four-level sensitivity label taxonomy and publishes it to a pilot group.

.DESCRIPTION
    PRE-CHECK  : tenant check, reads existing labels, reports what already exists.
    ACTION     : creates missing labels (encryption, footer, dynamic watermark), sets priority,
                 creates the label policy scoped to the pilot group.
    POST-VERIFY: run Test-SensitivityLabels.ps1 to read the configuration back.

    The script is idempotent: existing labels are reported, never overwritten.
    Use -WhatIf first.

    Requires a session opened with Connect-LabIPPS (common/M365Lab.Common.ps1)
    and the Compliance Administrator or Information Protection Admin role.

.EXAMPLE
    . ./common/M365Lab.Common.ps1
    Connect-LabIPPS -UserPrincipalName admin@contosofiduciaire.onmicrosoft.com
    Assert-LabTenant -ExpectedTenantId <lab-tenant-guid> -Service ExchangeOnline
    ./01-copilot-readiness/ws1-sensitivity-labels/Deploy-SensitivityLabels.ps1 -ConfigPath ./01-copilot-readiness/ws1-sensitivity-labels/config/labels.json -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory)][string]$ConfigPath
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../../common/M365Lab.Common.ps1')

$config = Get-Content -Path $ConfigPath -Raw | ConvertFrom-Json

# ---------- PRE-CHECK ----------
if (-not (Get-Command -Name Get-Label -ErrorAction SilentlyContinue)) {
    throw 'Get-Label not available. Connect with Connect-LabIPPS first.'
}
$existing = @(Get-Label | Select-Object -ExpandProperty Name)
Write-LabLog ("{0} labels already in the tenant" -f $existing.Count)

# ---------- ACTION: labels ----------
$created = [System.Collections.Generic.List[string]]::new()
foreach ($label in $config.labels) {
    if ($existing -contains $label.name) {
        Write-LabLog "Label '$($label.name)' already exists, left unchanged" 'WARN'
        continue
    }

    $params = @{
        Name        = $label.name
        DisplayName = $label.displayName
        Tooltip     = $label.tooltip
        ContentType = $label.contentType
    }

    if ($label.encryption) {
        $params.EncryptionEnabled            = $true
        $params.EncryptionProtectionType     = 'Template'
        $params.EncryptionRightsDefinitions  = '{0}:{1}' -f $config.organizationDomain, $label.encryption.rights
        $params.EncryptionOfflineAccessDays  = [int]$label.encryption.offlineAccessDays   # 0 is used for 'never offline': confirm with Test-SensitivityLabels.ps1
        $params.EncryptionContentExpiredOnDateInDaysOrNever = 'Never'
    }

    if ($label.footer) {
        $params.ApplyContentMarkingFooterEnabled   = $true
        $params.ApplyContentMarkingFooterText      = $label.footer
        $params.ApplyContentMarkingFooterAlignment = 'Center'
    }

    if ($label.PSObject.Properties.Name -contains 'dynamicWatermark' -and $label.dynamicWatermark) {
        # Dynamic watermarking is generally available only for labels with admin-defined permissions
        $params.ApplyDynamicWatermarkingEnabled = $true
        $params.DynamicWatermarkDisplay         = $label.dynamicWatermark
    }

    if ($PSCmdlet.ShouldProcess($label.name, 'New-Label')) {
        New-Label @params | Out-Null
        $created.Add($label.name)
        Write-LabLog "Created label '$($label.name)'" 'OK'
    }
}

# ---------- ACTION: priority ----------
# Only labels created in this run: existing labels are never changed, and priority is tenant-wide.
foreach ($label in ($config.labels | Where-Object { $created -contains $_.name } | Sort-Object priority)) {
    if ($PSCmdlet.ShouldProcess($label.name, "Set priority $($label.priority)")) {
        Set-Label -Identity $label.name -Priority $label.priority
    }
}

# ---------- ACTION: label policy (ring 0) ----------
# Lesson L2: one policy publishing every label keeps the design simple and predictable.
# Learn documents -ExchangeLocation for mailboxes; scoping to a group is to be confirmed in the lab.
$policy = Get-LabelPolicy -ErrorAction SilentlyContinue | Where-Object Name -eq $config.policyName
if ($policy) {
    Write-LabLog "Label policy '$($config.policyName)' already exists, left unchanged" 'WARN'
}
elseif ($PSCmdlet.ShouldProcess($config.policyName, 'New-LabelPolicy')) {
    New-LabelPolicy -Name $config.policyName `
        -Labels ($config.labels.name) `
        -ExchangeLocation $config.pilotGroup | Out-Null
    Write-LabLog "Created label policy '$($config.policyName)' scoped to $($config.pilotGroup)" 'OK'
}

Write-LabLog 'Done. Set the default label (Internal) in the policy settings in the Purview portal, then run Test-SensitivityLabels.ps1.'
