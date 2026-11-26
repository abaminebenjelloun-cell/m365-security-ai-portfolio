#Requires -Version 7.2
<#
.SYNOPSIS
    Offline tests: no tenant, no Pester, no network. Runs the module against an in-memory fake of the
    Graph Entitlement Management endpoints it calls.

.DESCRIPTION
    1. The sample configuration passes Test-EmConfig; broken configurations are rejected.
    2. ConvertTo-EmPolicyBody produces the expected Graph v1.0 shape (stages, expiry, review schedule).
    3. Plan on an empty tenant reports Create for every object and writes nothing.
    4. Apply builds everything; a second Plan reports only NoChange (idempotent).
    5. A policy changed in the tenant is reported as Update (drift), and Apply corrects it.
    6. Objects created outside the file are reported as Unmanaged and never deleted.
    7. Apply -WhatIf writes nothing.
    8. A missing group or user fails pre-flight before any write.
    9. A write that fails mid-run stops the run with a Failed record; the next run resumes and converges.

    What this does NOT prove: that Microsoft Graph accepts every body. That needs a run in a test tenant.

.EXAMPLE
    pwsh ./07-identity-governance/tests/Invoke-OfflineTests.ps1
#>
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
Import-Module (Join-Path $PSScriptRoot '../EntitlementManagement.psm1') -Force
$configPath = Join-Path $PSScriptRoot '../config/catalog-finance.json'
$config = Import-EmConfig -Path $configPath -TenantDomain 'contoso.example'

$script:failed = 0
function Assert-That([bool]$Condition, [string]$Message) {
    if ($Condition) { Write-Host "  PASS  $Message" -ForegroundColor Green }
    else { Write-Host "  FAIL  $Message" -ForegroundColor Red; $script:failed++ }
}

# ---------------- in-memory fake tenant ----------------
$script:T = $null
$script:Writes = 0
$script:FailOn = $null
$script:Throttle = 0
$script:Throttled = 0
function Reset-FakeTenant {
    $script:Writes = 0
    $script:FailOn = $null
    $script:Throttle = 0
    $script:Throttled = 0
    Clear-EmPrincipalCache
    $script:T = @{
        groups = @{}; users = @{ 'finance.owner@contoso.example' = 'u-finance-owner' }
        catalogs = @(); resources = @(); packages = @(); scopes = @(); policies = @(); incompatible = @()
    }
    foreach ($g in 'SG-Finance-Reporting-Readers', 'SG-Finance-Payments-Preparers', 'SG-Finance-Payments-Approvers',
        'M365-Finance-Team', 'SG-Dept-Finance', 'SG-Finance-Leads', 'SG-Finance-Access-Approvers', 'SG-Internal-Control') {
        $script:T.groups[$g] = 'g-' + ($g.ToLowerInvariant() -replace '[^a-z0-9]+', '-')
    }
}
function New-FakeId([string]$Prefix) { '{0}-{1}' -f $Prefix, ([guid]::NewGuid().ToString('N').Substring(0, 8)) }
function ConvertTo-Obj($h) { $h | ConvertTo-Json -Depth 20 | ConvertFrom-Json }

# Shadows the Microsoft.Graph cmdlet: the module's Invoke-EmGraph resolves to this function.
function global:Invoke-MgGraphRequest {
    [CmdletBinding()]
    param([string]$Method, [string]$Uri, $Body, [string]$ContentType, [string]$OutputType,
        [switch]$SkipHttpErrorCheck, [string]$StatusCodeVariable, [string]$ResponseHeadersVariable)
    $u = [uri]::UnescapeDataString(($Uri -replace '^https://graph.microsoft.com/v1.0/', ''))
    $b = if ($Body) { $Body | ConvertFrom-Json -AsHashtable } else { $null }
    $em = 'identityGovernance/entitlementManagement'
    # Like the real cmdlet with -SkipHttpErrorCheck: the status goes to the caller's variable, no throw.
    $vars = $PSCmdlet.SessionState.PSVariable
    $setStatus = { param($code, $headers)
        if ($StatusCodeVariable) { $vars.Set($StatusCodeVariable, $code) }
        if ($ResponseHeadersVariable) { $vars.Set($ResponseHeadersVariable, $headers) } }
    if ($script:Throttle -gt 0 -and $Method -ne 'GET') {
        $script:Throttle--; $script:Throttled++
        & $setStatus 429 @{ 'Retry-After' = @('1') }
        return [pscustomobject]@{ error = [pscustomobject]@{ code = 'TooManyRequests'; message = 'Simulated throttling' } }
    }
    if ($script:FailOn -and "$Method $u" -match $script:FailOn) {
        & $setStatus 400 @{}
        return [pscustomobject]@{ error = [pscustomobject]@{ code = 'BadRequest'; message = 'Simulated Graph error' } }
    }
    & $setStatus $(if ($Method -eq 'POST') { 201 } else { 200 }) @{}
    if ($Method -ne 'GET') { $script:Writes++ }
    $list = { param($items) [pscustomobject]@{ value = @($items | ForEach-Object { ConvertTo-Obj $_ }) } }

    switch -Regex ("$Method $u") {
        "^GET groups\?\`$filter=displayName eq '(.+?)'&" {
            $id = $script:T.groups[$Matches[1].Replace("''", "'")]; return & $list @(if ($id) { @{ id = $id } }) }
        '^GET users/([^?]+)' { return [pscustomobject]@{ id = $script:T.users[$Matches[1]] } }
        "^GET $em/catalogs\?\`$filter=displayName eq '(.+)'$" {
            return & $list @($script:T.catalogs | Where-Object { $_.displayName -eq $Matches[1] }) }
        "^POST $em/catalogs$" { $c = $b + @{ id = (New-FakeId 'cat') }; $script:T.catalogs += $c; return ConvertTo-Obj $c }
        "^GET $em/catalogs/([^/]+)/resources$" {
            $cid = $Matches[1]; return & $list @($script:T.resources | Where-Object { $_.catalogId -eq $cid }) }
        "^POST $em/resourceRequests$" {
            $script:T.resources += @{ id = (New-FakeId 'res'); originId = $b.resource.originId; catalogId = $b.catalog.id }; return [pscustomobject]@{ id = 'req' } }
        # Real Graph v1.0 has no catalogs/{id}/accessPackages path: the fake returns 404 for it, like the service.
        "^GET $em/catalogs/([^/]+)/accessPackages" {
            & $setStatus 404 @{}; return [pscustomobject]@{ error = [pscustomobject]@{ code = 'NotFound'; message = 'No HTTP resource was found that matches the request URI' } } }
        "^GET $em/accessPackages\?\`$expand=catalog$" { return & $list @($script:T.packages) }
        "^POST $em/accessPackages$" { $p = $b + @{ id = (New-FakeId 'ap') }; $script:T.packages += $p; return ConvertTo-Obj $p }
        "^PATCH $em/accessPackages/([^/?]+)$" {
            $p = $script:T.packages | Where-Object { $_.id -eq $Matches[1] }; foreach ($k in $b.Keys) { $p[$k] = $b[$k] }; return $null }
        "^GET $em/accessPackages/([^/?]+)\?\`$expand=resourceRoleScopes" {
            $apId = $Matches[1]
            return ConvertTo-Obj @{ id = $apId; resourceRoleScopes = @($script:T.scopes | Where-Object { $_.ap -eq $apId } | ForEach-Object { @{ role = @{ originId = $_.originId } } }) } }
        "^GET $em/catalogs/[^/]+/resourceRoles\?\`$filter=\(originSystem eq 'AadGroup' and resource/id eq '([^']+)'\)" {
            $r = $script:T.resources | Where-Object { $_.id -eq $Matches[1] }
            return & $list @(foreach ($role in 'Member', 'Owner') { @{ id = (New-FakeId 'role'); originId = "${role}_$($r.originId)" } }) }
        "^POST $em/accessPackages/([^/]+)/resourceRoleScopes$" {
            $script:T.scopes += @{ ap = $Matches[1]; originId = $b.role.originId }; return [pscustomobject]@{ id = 'scope' } }
        "^GET $em/assignmentPolicies\?\`$filter=accessPackage/id eq '([^']+)'" {
            $apId = $Matches[1]; return & $list @($script:T.policies | Where-Object { $_.accessPackage.id -eq $apId }) }
        "^POST $em/assignmentPolicies$" { $p = $b + @{ id = (New-FakeId 'pol') }; $script:T.policies += $p; return ConvertTo-Obj $p }
        "^PUT $em/assignmentPolicies/(.+)$" {
            $pid_ = $Matches[1]; $script:T.policies = @($script:T.policies | Where-Object { $_.id -ne $pid_ }) + @($b); return $null }
        "^GET $em/accessPackages/([^/]+)/incompatibleAccessPackages$" {
            $apId = $Matches[1]
            return & $list @($script:T.incompatible | Where-Object { $_.ap -eq $apId } | ForEach-Object {
                    $other = $_.other; @{ id = $other; displayName = ($script:T.packages | Where-Object { $_.id -eq $other }).displayName } }) }
        "^POST $em/accessPackages/([^/]+)/incompatibleAccessPackages/\`$ref$" {
            $script:T.incompatible += @{ ap = $Matches[1]; other = ($b.'@odata.id' -split '/')[-1] }; return $null }
        default { throw "Fake tenant: unhandled call $Method $u" }
    }
}
function global:Start-Sleep { param($Seconds) }

$fakeResolve = { param($ref) "id-of-$ref" }
function Get-Actions($changes) { @($changes | Group-Object Action | ForEach-Object { '{0}={1}' -f $_.Name, $_.Count }) -join ' ' }

Write-Host "`n1. Configuration validation"
foreach ($file in Get-ChildItem (Join-Path $PSScriptRoot '../config') -Filter *.json) {
    $errs = Test-EmConfig -Config (Import-EmConfig -Path $file.FullName -TenantDomain 'contoso.example')
    Assert-That ($errs.Count -eq 0) "$($file.Name) is valid $($errs -join '; ')"
}
$bad = $config | ConvertTo-Json -Depth 20 | ConvertFrom-Json
$bad.accessPackages[0].resourceRoles[0].resource = 'does-not-exist'
$bad.accessPackages[1].incompatibleWith = @('Unknown package')
$bad.accessPackages[2].policies[0].approvalStages += @($bad.accessPackages[2].policies[0].approvalStages) + @($bad.accessPackages[2].policies[0].approvalStages)
$bad.accessPackages[3].policies[0].accessReview.onNoResponse = 'deleteEverything'
$errs = Test-EmConfig -Config $bad
Assert-That ($errs.Count -eq 4) "broken configuration rejected with 4 errors (got $($errs.Count))"
$internal = $config | ConvertTo-Json -Depth 20 | ConvertFrom-Json
$internal.catalog.isExternallyVisible = $false
$errs = Test-EmConfig -Config $internal
Assert-That ($errs.Count -eq 1 -and $errs[0] -like '*isExternallyVisible*') 'connected-organisation policy rejected in an internal-only catalog'

Write-Host "`n2. Policy body"
$body = ConvertTo-EmPolicyBody -Policy $config.accessPackages[1].policies[0] -AccessPackageId 'ap-1' -Resolve $fakeResolve
Assert-That ($body.requestApprovalSettings.stages.Count -eq 2) 'two approval stages'
Assert-That ($body.requestApprovalSettings.stages[0].primaryApprovers[0].'@odata.type' -eq '#microsoft.graph.requestorManager') 'stage 1 is the requestor manager'
Assert-That ($body.requestApprovalSettings.stages[0].fallbackPrimaryApprovers[0].groupId -eq 'id-of-group:SG-Finance-Access-Approvers') 'stage 1 has a fallback approver group'
Assert-That ($body.expiration.duration -eq 'P180D') 'assignment expires after 180 days'
Assert-That ($body.reviewSettings.schedule.recurrence.pattern.interval -eq 3) 'quarterly access review'
Assert-That ($body.reviewSettings.expirationBehavior -eq 'removeAccess') 'access removed when reviewers do not respond'
$an = ConvertTo-EmPolicyBody -Policy $config.accessPackages[0].policies[0] -AccessPackageId 'ap-0' -Resolve $fakeResolve
Assert-That ($an.reviewSettings.primaryReviewers[0].'@odata.type' -eq '#microsoft.graph.targetManager' -and $an.requestApprovalSettings.stages[0].primaryApprovers[0].'@odata.type' -eq '#microsoft.graph.requestorManager') 'manager is targetManager as reviewer, requestorManager as approver'
Assert-That ($body.specificAllowedTargets[0].groupId -eq 'id-of-group:SG-Dept-Finance') 'only Finance department can request'
$guest = ConvertTo-EmPolicyBody -Policy $config.accessPackages[3].policies[0] -AccessPackageId 'ap-4' -Resolve $fakeResolve
Assert-That ($guest.allowedTargetScope -eq 'allConfiguredConnectedOrganizationUsers' -and $guest.specificAllowedTargets.Count -eq 0) 'auditor package targets connected organisations only'
Assert-That ((Get-EmPolicyFingerprint -Policy $body) -eq (Get-EmPolicyFingerprint -Policy (ConvertTo-Obj $body))) 'fingerprint identical for hashtable and Graph-shaped object'

Write-Host "`n3. Plan on an empty tenant"
Reset-FakeTenant
$plan = Sync-EmCatalog -Config $config -Mode Plan
Assert-That ($script:Writes -eq 0) 'Plan made no write calls'
Assert-That (@($plan | Where-Object Action -ne 'Create').Count -eq 0) "every object planned as Create ($(Get-Actions $plan))"

Write-Host "`n4. Apply, then Plan again"
$applied = Sync-EmCatalog -Config $config -Mode Apply -Confirm:$false
Assert-That ($script:T.packages.Count -eq 4 -and $script:T.policies.Count -eq 4) '4 access packages and 4 policies created'
Assert-That ($script:T.resources.Count -eq 4 -and $script:T.scopes.Count -eq 7) '4 catalog resources and 7 resource role scopes'
Assert-That ($script:T.incompatible.Count -eq 2) 'Payments Preparer and Approver marked incompatible both ways'
$script:Writes = 0
$replan = Sync-EmCatalog -Config $config -Mode Plan
Assert-That (@($replan | Where-Object Action -ne 'NoChange').Count -eq 0) "second Plan is clean ($(Get-Actions $replan))"
$again = Sync-EmCatalog -Config $config -Mode Apply -Confirm:$false
Assert-That ($script:Writes -eq 0) 'second Apply made no write calls (idempotent)'

Write-Host "`n5. Drift"
($script:T.policies | Where-Object displayName -eq 'Finance staff - two-stage approval').expiration.duration = 'P365D'
$drift = Sync-EmCatalog -Config $config -Mode Plan
$upd = @($drift | Where-Object Action -eq 'Update')
Assert-That ($upd.Count -eq 1 -and $upd[0].Name -like '*two-stage approval') 'expiry changed in the portal is reported as Update'
Sync-EmCatalog -Config $config -Mode Apply -Confirm:$false | Out-Null
Assert-That (@(Sync-EmCatalog -Config $config -Mode Plan | Where-Object Action -ne 'NoChange').Count -eq 0) 'Apply restored the policy from the file'

Write-Host "`n6. Unmanaged objects"
$cid = $script:T.catalogs[0].id
$script:T.packages += @{ id = 'ap-manual'; displayName = 'Finance - Created in portal'; catalog = @{ id = $cid } }
$before = $script:T.packages.Count
$um = Sync-EmCatalog -Config $config -Mode Apply -Confirm:$false
Assert-That (@($um | Where-Object Action -eq 'Unmanaged').Count -eq 1) 'portal-created package reported as Unmanaged'
Assert-That ($script:T.packages.Count -eq $before) 'and left in place, not deleted'

$apId = ($script:T.packages | Where-Object displayName -eq 'Finance - Analyst').id
$script:T.scopes += @{ ap = $apId; originId = 'Owner_g-manual' }
$us = @(Sync-EmCatalog -Config $config -Mode Plan | Where-Object { $_.Kind -eq 'RoleScope' -and $_.Action -eq 'Unmanaged' })
Assert-That ($us.Count -eq 1) 'role scope added in the portal reported as Unmanaged'
$script:T.scopes = @($script:T.scopes | Where-Object originId -ne 'Owner_g-manual')

Write-Host "`n6b. Normalisation and carry-over"
$pol = $script:T.policies | Where-Object displayName -eq 'Finance staff - two-stage approval'
$pol.expiration.duration = 'P180DT0S'
$pol.requestApprovalSettings.stages[0].durationBeforeAutomaticDenial = 'P5DT0H0M0S'
Assert-That (@(Sync-EmCatalog -Config $config -Mode Plan | Where-Object Action -eq 'Update').Count -eq 0) 'P180DT0S and P180D compare equal (no false drift)'
$pol.expiration.duration = 'P90D'
$pol.questions = @(@{ '@odata.type' = '#microsoft.graph.accessPackageTextInputQuestion'; text = @{ defaultText = 'Cost centre?' } })
Sync-EmCatalog -Config $config -Mode Apply -Confirm:$false | Out-Null
$after = $script:T.policies | Where-Object displayName -eq 'Finance staff - two-stage approval'
Assert-That ($after.expiration.duration -eq 'P180D' -and @($after.questions).Count -eq 1) 'PUT restored expiry and kept the question added in the portal'
$noDur = $config | ConvertTo-Json -Depth 20 | ConvertFrom-Json
$noDur.accessPackages[0].policies[0].accessReview.PSObject.Properties.Remove('durationDays')
Assert-That (@(Test-EmConfig -Config $noDur | Where-Object { $_ -like '*durationDays*' }).Count -eq 1) 'missing accessReview.durationDays rejected before any write'
$prev = [cultureinfo]::CurrentCulture
[cultureinfo]::CurrentCulture = 'fi-FI'
$fi = ConvertTo-EmPolicyBody -Policy $config.accessPackages[0].policies[0] -AccessPackageId 'ap-1' -Resolve $fakeResolve
[cultureinfo]::CurrentCulture = $prev
Assert-That ($fi.reviewSettings.schedule.startDateTime -eq '2027-01-04T08:00:00Z') 'review start date is culture-independent'

Write-Host "`n7. WhatIf"
Reset-FakeTenant
Sync-EmCatalog -Config $config -Mode Apply -WhatIf | Out-Null
Assert-That ($script:Writes -eq 0) 'Apply -WhatIf made no write calls'

Write-Host "`n8. Pre-flight"
Reset-FakeTenant
$script:T.groups.Remove('SG-Internal-Control')
$msg = try { Sync-EmCatalog -Config $config -Mode Apply -Confirm:$false | Out-Null; '' } catch { $_.Exception.Message }
Assert-That ($msg -like 'Pre-flight failed*SG-Internal-Control*') 'missing group reported by name before any change'
Assert-That ($script:Writes -eq 0) 'pre-flight failure made no write calls'

Write-Host "`n9. Failure and recovery"
Reset-FakeTenant
$script:FailOn = '^POST .*/assignmentPolicies$'
$partial = Sync-EmCatalog -Config $config -Mode Apply -Confirm:$false
$fail = @($partial | Where-Object Action -eq 'Failed')
Assert-That ($fail.Count -eq 1 -and $fail[0].Detail -like '*Simulated Graph error*') 'run stopped at the failed write with the Graph error'
Assert-That ($script:T.packages.Count -eq 1 -and $script:T.policies.Count -eq 0) 'objects before the failure stay in place'
$script:FailOn = $null
$resume = Sync-EmCatalog -Config $config -Mode Apply -Confirm:$false
Assert-That (@($resume | Where-Object Action -eq 'Failed').Count -eq 0 -and $script:T.policies.Count -eq 4) 're-run resumed and completed'
Assert-That (@(Sync-EmCatalog -Config $config -Mode Plan | Where-Object Action -ne 'NoChange').Count -eq 0) 'tenant matches the file after recovery'

Write-Host "`n10. Throttling"
Reset-FakeTenant
$script:Throttle = 2
$th = Sync-EmCatalog -Config $config -Mode Apply -Confirm:$false
Assert-That ($script:Throttled -eq 2 -and @($th | Where-Object Action -eq 'Failed').Count -eq 0 -and $script:T.policies.Count -eq 4) 'two HTTP 429 responses retried after Retry-After, run completed'

# Remove the fakes so a real Graph session in the same shell is not shadowed afterwards.
Remove-Item -Path function:global:Invoke-MgGraphRequest, function:global:Start-Sleep -ErrorAction SilentlyContinue

Write-Host ''
if ($script:failed) { Write-Host "$script:failed test(s) failed" -ForegroundColor Red; exit 1 }
Write-Host 'All offline tests passed' -ForegroundColor Green
