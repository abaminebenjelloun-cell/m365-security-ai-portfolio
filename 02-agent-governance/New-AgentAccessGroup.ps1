#Requires -Version 7.2
<#
.SYNOPSIS
    Creates the dynamic Entra security group used to scope who can use agents.

.DESCRIPTION
    The group contains every enabled member account, minus explicit exclusions (for example a
    user whose agent usage is suspended pending review). It is then selected in
    Microsoft 365 admin center > Agents > Settings > User access > Specific users or groups.

    Why a dynamic group: new joiners are included automatically, leavers removed automatically,
    and an exclusion is a one-line change in the rule, visible in the audit log.

    Requires Microsoft Entra ID P1 (dynamic membership) and Group.ReadWrite.All.
    Supports -WhatIf.

.EXAMPLE
    . ./common/M365Lab.Common.ps1
    Connect-LabGraph -Scopes 'Group.ReadWrite.All'
    Assert-LabTenant -ExpectedTenantId <lab-tenant-guid>
    ./02-agent-governance/New-AgentAccessGroup.ps1 -ExcludedUpn 'bruno@contosofiduciaire.onmicrosoft.com' -WhatIf
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$DisplayName = 'Lab - Agent access',
    [string[]]$ExcludedUpn = @()
)

$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot '../common/M365Lab.Common.ps1')

# Build the rule: enabled members, minus exclusions
$rule = '(user.accountEnabled -eq true) and (user.userType -eq "Member")'
foreach ($upn in $ExcludedUpn) {
    $rule += ' and (user.userPrincipalName -ne "{0}")' -f $upn
}
Write-LabLog "Membership rule: $rule"

# PRE-CHECK: no group with the same name
$existing = Get-MgGroup -Filter "displayName eq '$DisplayName'" -ErrorAction SilentlyContinue
if ($existing) { throw "A group named '$DisplayName' already exists ($($existing.Id))." }

if ($PSCmdlet.ShouldProcess($DisplayName, 'Create dynamic security group')) {
    $group = New-MgGroup -DisplayName $DisplayName `
        -Description 'Users allowed to use agents. Managed by rule, exclusions documented in the exception register.' `
        -MailEnabled:$false -MailNickname ($DisplayName -replace '[^a-zA-Z0-9]', '') `
        -SecurityEnabled `
        -GroupTypes 'DynamicMembership' `
        -MembershipRule $rule `
        -MembershipRuleProcessingState 'On'

    Write-LabLog "Created group $($group.DisplayName) ($($group.Id))" 'OK'
    Write-LabLog 'Membership is calculated asynchronously. Check the member count in Entra before selecting the group in the agent settings.'
    Write-LabLog 'Hygiene check: the rule also includes enabled functional and shared accounts. List them for the client.' 'WARN'
}
