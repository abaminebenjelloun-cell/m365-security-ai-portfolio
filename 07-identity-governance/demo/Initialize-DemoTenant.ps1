#Requires -Version 7.2
<#
.SYNOPSIS
    Prepares an empty lab tenant for the Entitlement Management demo: test users with managers,
    the groups the Finance catalog uses, memberships, licences, and an app registration for the
    Azure DevOps pipeline.

.DESCRIPTION
    Idempotent: users, groups, memberships and the app are created only when missing.
    New users get a random password, shown once and written to output/demo-users.csv
    (output/ is git-ignored). The pipeline app secret is shown once and never written to disk.

    Run as a Global Administrator of the LAB tenant only.

.EXAMPLE
    Connect-MgGraph -Scopes 'User.ReadWrite.All','Group.ReadWrite.All','Organization.Read.All','Application.ReadWrite.All','AppRoleAssignment.ReadWrite.All' -UseDeviceCode
    ./07-identity-governance/demo/Initialize-DemoTenant.ps1
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$UsageLocation = 'GB',
    [switch]$SkipPipelineApp
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$g = 'https://graph.microsoft.com/v1.0'

function Invoke-G([string]$Method = 'GET', [string]$Uri, $Body) {
    $p = @{ Method = $Method; Uri = "$g/$Uri"; OutputType = 'PSObject' }
    if ($null -ne $Body) { $p.Body = ($Body | ConvertTo-Json -Depth 10); $p.ContentType = 'application/json' }
    Invoke-MgGraphRequest @p
}
function New-DemoPassword { 'Kd!' + -join ((48..57) + (65..90) + (97..122) | Get-Random -Count 13 | ForEach-Object { [char]$_ }) }

$ctx = Get-MgContext
if (-not $ctx) { throw 'Connect-MgGraph first (see .EXAMPLE).' }
$domain = @((Invoke-G -Uri 'domains').value | Where-Object isDefault)[0].id
Write-Host "Tenant $($ctx.TenantId), default domain $domain" -ForegroundColor Cyan

# ---------- groups ----------
$groupNames = @(
    'SG-Finance-Reporting-Readers', 'SG-Finance-Payments-Preparers', 'SG-Finance-Payments-Approvers', 'M365-Finance-Team',
    'SG-Dept-Finance', 'SG-Finance-Leads', 'SG-Finance-Access-Approvers', 'SG-Internal-Control',
    'SG-HR-Records-Readers', 'SG-HR-Payroll-Editors', 'SG-Dept-HR'
)
$groups = @{}
foreach ($name in $groupNames) {
    $found = @((Invoke-G -Uri ("groups?`$filter=displayName eq '{0}'&`$select=id" -f $name)).value)
    if ($found.Count) { $groups[$name] = $found[0].id; Write-Host "  group exists   $name"; continue }
    if ($PSCmdlet.ShouldProcess($name, 'Create security group')) {
        $nick = ($name -replace '[^A-Za-z0-9]', '').ToLowerInvariant()
        $groups[$name] = (Invoke-G -Method POST -Uri 'groups' -Body @{
                displayName = $name; mailEnabled = $false; mailNickname = $nick; securityEnabled = $true
                description = 'Entitlement Management demo (synthetic)'
            }).id
        Write-Host "  group created  $name" -ForegroundColor Green
    }
}

# ---------- users ----------
# alias, display name, manager alias, groups
$people = @(
    @('fin.manager', 'Morgan Finance-Manager', $null, @('SG-Dept-Finance')),
    @('fin.analyst', 'Alex Analyst', 'fin.manager', @('SG-Dept-Finance')),
    @('fin.preparer', 'Pat Preparer', 'fin.manager', @('SG-Dept-Finance')),
    @('fin.lead', 'Lee Finance-Lead', 'fin.manager', @('SG-Dept-Finance', 'SG-Finance-Leads')),
    @('fin.nomanager', 'Noa No-Manager', $null, @('SG-Dept-Finance')),
    @('finance.owner', 'Finance Resource-Owner', $null, @('SG-Finance-Access-Approvers')),
    @('ic.reviewer', 'Ian Internal-Control', $null, @('SG-Internal-Control')),
    @('hr.head', 'Harper HR-Head', $null, @('SG-Dept-HR')),
    @('hr.officer', 'Robin HR-Officer', 'hr.head', @('SG-Dept-HR'))
)
$users = @{}
$created = [System.Collections.Generic.List[object]]::new()
foreach ($p in $people) {
    $upn = "$($p[0])@$domain"
    $u = try { Invoke-G -Uri ("users/{0}?`$select=id" -f $upn) } catch { $null }
    if ($u) { $users[$p[0]] = $u.id; Write-Host "  user exists    $upn"; continue }
    if ($PSCmdlet.ShouldProcess($upn, 'Create user')) {
        $pw = New-DemoPassword
        $users[$p[0]] = (Invoke-G -Method POST -Uri 'users' -Body @{
                accountEnabled = $true; displayName = $p[1]; mailNickname = ($p[0] -replace '\.', '')
                userPrincipalName = $upn; usageLocation = $UsageLocation; department = 'Finance'
                passwordProfile = @{ password = $pw; forceChangePasswordNextSignIn = $false }
            }).id
        $created.Add([pscustomobject]@{ UserPrincipalName = $upn; Password = $pw; Role = $p[1] })
        Write-Host "  user created   $upn" -ForegroundColor Green
    }
}

# ---------- managers and memberships ----------
foreach ($p in $people) {
    $id = $users[$p[0]]
    if (-not $id) { continue }
    if ($p[2] -and $PSCmdlet.ShouldProcess($p[0], "Set manager $($p[2])")) {
        Invoke-G -Method PUT -Uri "users/$id/manager/`$ref" -Body @{ '@odata.id' = "$g/users/$($users[$p[2]])" } | Out-Null
    }
    foreach ($gn in $p[3]) {
        $members = @((Invoke-G -Uri "groups/$($groups[$gn])/members?`$select=id").value | ForEach-Object id)
        if ($members -contains $id) { continue }
        if ($PSCmdlet.ShouldProcess("$($p[0]) -> $gn", 'Add member')) {
            Invoke-G -Method POST -Uri "groups/$($groups[$gn])/members/`$ref" -Body @{ '@odata.id' = "$g/directoryObjects/$id" } | Out-Null
        }
    }
}

# ---------- licences ----------
$sku = @((Invoke-G -Uri 'subscribedSkus').value | Where-Object {
        @($_.servicePlans.servicePlanName) -match 'AAD_PREMIUM_P2|Governance' -and $_.prepaidUnits.enabled -gt $_.consumedUnits
    }) | Select-Object -First 1
if (-not $sku) {
    Write-Warning 'No Entra ID P2 or ID Governance licence with free seats found. Start the trial first (runbook step 1).'
}
else {
    foreach ($p in $people) {
        $id = $users[$p[0]]
        $has = @((Invoke-G -Uri "users/$id/licenseDetails").value | ForEach-Object skuId) -contains $sku.skuId
        if (-not $has -and $PSCmdlet.ShouldProcess($p[0], "Assign $($sku.skuPartNumber)")) {
            Invoke-G -Method PATCH -Uri "users/$id" -Body @{ usageLocation = $UsageLocation } | Out-Null
            Invoke-G -Method POST -Uri "users/$id/assignLicense" -Body @{ addLicenses = @(@{ skuId = $sku.skuId; disabledPlans = @() }); removeLicenses = @() } | Out-Null
        }
    }
    Write-Host "  licence $($sku.skuPartNumber) assigned to demo users" -ForegroundColor Green
}

# ---------- pipeline app registration ----------
if (-not $SkipPipelineApp) {
    $appName = 'kydra-entitlement-pipeline-demo'
    $app = @((Invoke-G -Uri "applications?`$filter=displayName eq '$appName'").value) | Select-Object -First 1
    if (-not $app -and $PSCmdlet.ShouldProcess($appName, 'Create app registration')) {
        $app = Invoke-G -Method POST -Uri 'applications' -Body @{ displayName = $appName; signInAudience = 'AzureADMyOrg' }
        Start-Sleep -Seconds 10
    }
    $sp = @((Invoke-G -Uri "servicePrincipals?`$filter=appId eq '$($app.appId)'").value) | Select-Object -First 1
    if (-not $sp) { $sp = Invoke-G -Method POST -Uri 'servicePrincipals' -Body @{ appId = $app.appId } }

    $graphSp = @((Invoke-G -Uri "servicePrincipals?`$filter=displayName eq 'Microsoft Graph'&`$select=id,appRoles").value)[0]
    $granted = @((Invoke-G -Uri "servicePrincipals/$($sp.id)/appRoleAssignments").value | ForEach-Object appRoleId)
    foreach ($perm in 'EntitlementManagement.ReadWrite.All', 'Group.ReadWrite.All', 'User.Read.All') {
        $role = $graphSp.appRoles | Where-Object value -eq $perm
        if ($granted -contains $role.id) { continue }
        if ($PSCmdlet.ShouldProcess($perm, 'Grant application permission (admin consent)')) {
            Invoke-G -Method POST -Uri "servicePrincipals/$($sp.id)/appRoleAssignments" -Body @{
                principalId = $sp.id; resourceId = $graphSp.id; appRoleId = $role.id
            } | Out-Null
        }
    }
    if ($PSCmdlet.ShouldProcess($appName, 'Add a 30-day client secret')) {
        $secret = Invoke-G -Method POST -Uri "applications/$($app.id)/addPassword" -Body @{
            passwordCredential = @{ displayName = 'ado-demo'; endDateTime = (Get-Date).AddDays(30).ToUniversalTime().ToString('o') }
        }
        Write-Host "`nAzure DevOps variable group 'entra-demo' values (secret shown once, not saved):" -ForegroundColor Cyan
        Write-Host "  TenantId     = $($ctx.TenantId)"
        Write-Host "  TenantDomain = $domain"
        Write-Host "  ClientId     = $($app.appId)"
        Write-Host "  ClientSecret = $($secret.secretText)   <- mark as secret (lock icon)"
    }
}

if ($created.Count) {
    $out = Join-Path (Get-Location) 'output'
    if (-not (Test-Path $out)) { New-Item -ItemType Directory -Path $out | Out-Null }
    $created | Export-Csv -Path (Join-Path $out 'demo-users.csv') -NoTypeInformation
    Write-Host "`nNew demo users (also in output/demo-users.csv):" -ForegroundColor Cyan
    $created | Format-Table -AutoSize | Out-Host
}
Write-Host 'Tenant ready for the demo.' -ForegroundColor Green
