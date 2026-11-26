#Requires -Version 7.2
<#
.SYNOPSIS
    Configuration-driven Entitlement Management: one JSON file per catalog, applied through Microsoft Graph v1.0.

.DESCRIPTION
    Test-EmConfig          : validates a catalog file before anything touches the tenant.
    ConvertTo-EmPolicyBody : turns one policy block of the file into a Graph accessPackageAssignmentPolicy body.
    Get-EmPolicyFingerprint: the fields that define a policy, used to detect drift.
    Sync-EmCatalog         : walks catalog -> resources -> access packages -> role scopes -> policies
                             -> incompatible packages. -Mode Plan only reads and reports drift.
                             -Mode Apply creates or updates what differs. -WhatIf is honoured.

    Native Entra first: approvals, expiry and reviews stay in built-in policies. The module only
    deploys configuration. Nothing in the tenant is ever deleted: objects that exist in the tenant but
    not in the file are reported as 'Unmanaged' for a human decision.

    Requires Microsoft.Graph.Authentication (Connect-MgGraph) with
    EntitlementManagement.ReadWrite.All, Group.Read.All and User.Read.All (Plan needs only the Read scopes).
#>

Set-StrictMode -Version Latest

$script:GraphBase = 'https://graph.microsoft.com/v1.0'
$script:EmBase = 'identityGovernance/entitlementManagement'
$script:PrincipalCache = @{}

$script:Recurrence = @{ monthly = 1; quarterly = 3; semiannual = 6; annual = 12 }
$script:TargetScopes = @('specificDirectoryUsers', 'allMemberUsers', 'allDirectoryUsers', 'allConfiguredConnectedOrganizationUsers', 'allExternalUsers')
$script:NoResponse = @('keepAccess', 'removeAccess', 'acceptAccessRecommendation')

function Get-EmProp {
    # Optional property read that works under StrictMode.
    param($InputObject, [string]$Name, $Default = $null)
    if ($null -eq $InputObject) { return $Default }
    if ($InputObject -is [System.Collections.IDictionary]) {
        if ($InputObject.Contains($Name)) { return $InputObject[$Name] } else { return $Default }
    }
    $p = $InputObject.PSObject.Properties[$Name]
    if ($p) { return $p.Value } else { return $Default }
}

function ConvertTo-EmODataString {
    param([Parameter(Mandatory)][string]$Value)
    $Value.Replace("'", "''")
}

function Invoke-EmGraph {
    <#
    .SYNOPSIS
        Thin wrapper over Invoke-MgGraphRequest. GET follows paging and returns the items.
        Kept separate so tests can mock every call to the tenant.
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('GET', 'POST', 'PATCH', 'PUT')][string]$Method = 'GET',
        [Parameter(Mandatory)][string]$Uri,
        $Body
    )
    $full = if ($Uri -like 'https://*') { $Uri } else { "$script:GraphBase/$Uri" }
    if ($Method -eq 'GET') {
        $items = [System.Collections.Generic.List[object]]::new()
        $next = $full
        while ($next) {
            $page = Invoke-EmGraphWithRetry -Method GET -Uri $next
            $value = Get-EmProp $page 'value'
            if ($null -eq $value -and -not $page.PSObject.Properties['value']) { return $page }
            foreach ($v in @($value)) { if ($null -ne $v) { $items.Add($v) } }
            $next = Get-EmProp $page '@odata.nextLink'
        }
        return $items.ToArray()
    }
    $json = if ($null -ne $Body) { $Body | ConvertTo-Json -Depth 20 } else { $null }
    Invoke-EmGraphWithRetry -Method $Method -Uri $full -Json $json
}

function Invoke-EmGraphWithRetry {
    <#
    .SYNOPSIS
        Retries throttling (429) and transient service errors (500, 502, 503, 504) with exponential
        backoff, honouring Retry-After. Any other error surfaces at once with the Graph message.
    #>
    [CmdletBinding()]
    param([string]$Method, [string]$Uri, [string]$Json, [int]$MaxAttempts = 5)
    for ($attempt = 1; ; $attempt++) {
        try {
            if ($Method -eq 'GET') { return Invoke-MgGraphRequest -Method GET -Uri $Uri -OutputType PSObject }
            return Invoke-MgGraphRequest -Method $Method -Uri $Uri -Body $Json -ContentType 'application/json' -OutputType PSObject
        }
        catch {
            $status = 0
            $response = Get-EmProp $_.Exception 'Response'
            if ($response) { $status = [int](Get-EmProp $response 'StatusCode' 0) }
            if ($status -notin 429, 500, 502, 503, 504 -or $attempt -ge $MaxAttempts) {
                throw "Graph $Method $($Uri -replace '^https://graph.microsoft.com/v1.0/', '') failed (HTTP $status): $($_.Exception.Message)"
            }
            $wait = [math]::Pow(2, $attempt)
            $headers = Get-EmProp $response 'Headers'
            $retryAfter = if ($headers) { Get-EmProp (Get-EmProp $headers 'RetryAfter') 'Delta' } else { $null }
            if ($retryAfter) { $wait = [math]::Ceiling($retryAfter.TotalSeconds) }
            Write-Verbose "HTTP $status on $Method, retry $attempt of $($MaxAttempts - 1) in $wait s"
            Start-Sleep -Seconds $wait
        }
    }
}

function Resolve-EmPrincipal {
    <#
    .SYNOPSIS
        Resolves 'user:<upn>' or 'group:<displayName>' (or a bare group display name) to an object id.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Reference)

    if ($script:PrincipalCache.ContainsKey($Reference)) { return $script:PrincipalCache[$Reference] }
    if ($Reference -like 'user:*') {
        $upn = $Reference.Substring(5)
        $user = Invoke-EmGraph -Uri ("users/{0}?`$select=id" -f [uri]::EscapeDataString($upn))
        $id = $user.id
    }
    else {
        $name = if ($Reference -like 'group:*') { $Reference.Substring(6) } else { $Reference }
        $found = @(Invoke-EmGraph -Uri ("groups?`$filter=displayName eq '{0}'&`$select=id" -f (ConvertTo-EmODataString $name)))
        if ($found.Count -ne 1) { throw "Group '$name' resolved to $($found.Count) objects. Display names must be unique." }
        $id = $found[0].id
    }
    $script:PrincipalCache[$Reference] = $id
    $id
}

function Import-EmConfig {
    <#
    .SYNOPSIS
        Reads a catalog file. {tenantDomain} placeholders are replaced with -TenantDomain, or with the
        tenant's default verified domain read from Graph, so the same file works in any tenant.
    #>
    [CmdletBinding()]
    param([Parameter(Mandatory)][string]$Path, [string]$TenantDomain)
    $raw = Get-Content -Path $Path -Raw
    if ($raw -match '\{tenantDomain\}') {
        if (-not $TenantDomain) {
            $TenantDomain = @(Invoke-EmGraph -Uri 'domains') | Where-Object { $_.isDefault } | Select-Object -First 1 -ExpandProperty id
            if (-not $TenantDomain) { throw 'Could not read the default domain. Pass -TenantDomain.' }
        }
        $raw = $raw.Replace('{tenantDomain}', $TenantDomain)
    }
    $raw | ConvertFrom-Json
}

function Clear-EmPrincipalCache {
    <# .SYNOPSIS Forgets resolved ids, for a new session or tenant. #>
    [CmdletBinding()] param()
    $script:PrincipalCache.Clear()
}

function Test-EmConfig {
    <#
    .SYNOPSIS
        Validates a catalog configuration. Returns a list of error strings (empty = valid).
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param([Parameter(Mandatory)]$Config)

    $errors = [System.Collections.Generic.List[string]]::new()
    $catalog = Get-EmProp $Config 'catalog'
    if (-not (Get-EmProp $catalog 'displayName')) { $errors.Add('catalog.displayName is required') }

    $keys = @{}
    foreach ($r in @(Get-EmProp $Config 'resources' @())) {
        if ((Get-EmProp $r 'type') -ne 'group') { $errors.Add("resource '$(Get-EmProp $r 'key')': only type 'group' is supported in this version") }
        if ($keys.ContainsKey($r.key)) { $errors.Add("resource key '$($r.key)' is duplicated") }
        $keys[$r.key] = $true
    }

    $packages = @(Get-EmProp $Config 'accessPackages' @())
    $names = @($packages | ForEach-Object { $_.displayName })
    foreach ($dup in ($names | Group-Object | Where-Object Count -gt 1)) { $errors.Add("access package '$($dup.Name)' is duplicated") }

    $approverPattern = '^(manager|user:[^@\s]+@[^@\s]+|group:.+)$'
    foreach ($ap in $packages) {
        $label = "access package '$($ap.displayName)'"
        $roles = @(Get-EmProp $ap 'resourceRoles' @())
        if ($roles.Count -eq 0) { $errors.Add("${label}: at least one resource role is required") }
        foreach ($rr in $roles) {
            if (-not $keys.ContainsKey($rr.resource)) { $errors.Add("${label}: unknown resource key '$($rr.resource)'") }
            if ($rr.role -notin @('Member', 'Owner')) { $errors.Add("${label}: role must be Member or Owner") }
        }
        foreach ($inc in @(Get-EmProp $ap 'incompatibleWith' @())) {
            if ($inc -notin $names) { $errors.Add("${label}: incompatible package '$inc' is not defined in this file") }
            if ($inc -eq $ap.displayName) { $errors.Add("${label}: cannot be incompatible with itself") }
        }
        $policies = @(Get-EmProp $ap 'policies' @())
        if ($policies.Count -eq 0) { $errors.Add("${label}: at least one policy is required") }
        foreach ($p in $policies) {
            $pl = "$label policy '$($p.displayName)'"
            $scope = Get-EmProp (Get-EmProp $p 'targets') 'scope'
            if ($scope -notin $script:TargetScopes) { $errors.Add("${pl}: targets.scope '$scope' is not supported") }
            if ($scope -in 'allConfiguredConnectedOrganizationUsers', 'allExternalUsers' -and -not [bool](Get-EmProp $catalog 'isExternallyVisible' $false)) {
                $errors.Add("${pl}: targets.scope '$scope' needs catalog.isExternallyVisible = true")
            }
            if ($scope -eq 'specificDirectoryUsers' -and @(Get-EmProp $p.targets 'groups' @()).Count -eq 0) { $errors.Add("${pl}: specificDirectoryUsers needs at least one group") }
            if ([int](Get-EmProp $p 'expirationDays' 0) -le 0) { $errors.Add("${pl}: expirationDays must be greater than 0") }
            $stages = @(Get-EmProp $p 'approvalStages' @())
            if ($stages.Count -gt 3) { $errors.Add("${pl}: Entitlement Management supports at most 3 approval stages") }
            foreach ($s in $stages) {
                if ($s.approver -notmatch $approverPattern) { $errors.Add("${pl}: approver '$($s.approver)' must be manager, user:<upn> or group:<name>") }
                $fb = Get-EmProp $s 'fallback'
                if ($fb -and ($fb -eq 'manager' -or $fb -notmatch $approverPattern)) { $errors.Add("${pl}: fallback '$fb' must be user:<upn> or group:<name>") }
                if ([int](Get-EmProp $s 'timeoutDays' 0) -lt 1 -or [int]$s.timeoutDays -gt 14) { $errors.Add("${pl}: timeoutDays must be 1 to 14") }
            }
            $rv = Get-EmProp $p 'accessReview'
            if ($rv) {
                if ($rv.recurrence -notin $script:Recurrence.Keys) { $errors.Add("${pl}: recurrence must be one of $($script:Recurrence.Keys -join ', ')") }
                if ($rv.onNoResponse -notin $script:NoResponse) { $errors.Add("${pl}: onNoResponse must be one of $($script:NoResponse -join ', ')") }
                if ($rv.reviewer -notmatch $approverPattern) { $errors.Add("${pl}: reviewer '$($rv.reviewer)' is not valid") }
                $d = [datetime]::MinValue
                if (-not [datetime]::TryParseExact([string]$rv.startDate, 'yyyy-MM-dd', $null, 'None', [ref]$d)) { $errors.Add("${pl}: accessReview.startDate must be yyyy-MM-dd") }
            }
        }
    }
    , $errors.ToArray()
}

function ConvertTo-EmSubjectSet {
    param([Parameter(Mandatory)][string]$Reference, [Parameter(Mandatory)][scriptblock]$Resolve)
    switch -Wildcard ($Reference) {
        'manager' { return @{ '@odata.type' = '#microsoft.graph.requestorManager'; managerLevel = 1 } }
        'user:*' { return @{ '@odata.type' = '#microsoft.graph.singleUser'; userId = (& $Resolve $Reference) } }
        'group:*' { return @{ '@odata.type' = '#microsoft.graph.groupMembers'; groupId = (& $Resolve $Reference) } }
        default { throw "Unsupported approver reference '$Reference'" }
    }
}

function ConvertTo-EmPolicyBody {
    <#
    .SYNOPSIS
        Builds a Graph v1.0 accessPackageAssignmentPolicy body from one policy block of the config.
        -Resolve maps 'user:..' / 'group:..' references to object ids (injected so tests run offline).
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]$Policy,
        [Parameter(Mandatory)][string]$AccessPackageId,
        [Parameter(Mandatory)][scriptblock]$Resolve
    )

    $targets = @(foreach ($g in @(Get-EmProp $Policy.targets 'groups' @())) {
            @{ '@odata.type' = '#microsoft.graph.groupMembers'; groupId = (& $Resolve "group:$g") }
        })
    $stages = @(foreach ($s in @(Get-EmProp $Policy 'approvalStages' @())) {
            $fb = Get-EmProp $s 'fallback'
            @{
                durationBeforeAutomaticDenial   = 'P{0}D' -f [int]$s.timeoutDays
                isApproverJustificationRequired = $true
                isEscalationEnabled             = $false
                primaryApprovers                = @(ConvertTo-EmSubjectSet -Reference $s.approver -Resolve $Resolve)
                fallbackPrimaryApprovers        = @(if ($fb) { ConvertTo-EmSubjectSet -Reference $fb -Resolve $Resolve })
            }
        })
    $justification = [bool](Get-EmProp $Policy 'requireJustification' $true)

    $body = [ordered]@{
        displayName             = $Policy.displayName
        description             = Get-EmProp $Policy 'description' $Policy.displayName
        allowedTargetScope      = $Policy.targets.scope
        specificAllowedTargets  = $targets
        expiration              = @{ type = 'afterDuration'; duration = 'P{0}D' -f [int]$Policy.expirationDays }
        requestorSettings       = @{
            enableTargetsToSelfAddAccess     = $true
            enableTargetsToSelfUpdateAccess  = $true
            enableTargetsToSelfRemoveAccess  = $true
            allowCustomAssignmentSchedule    = $false
            enableOnBehalfRequestorsToAddAccess = $false
        }
        requestApprovalSettings = @{
            isApprovalRequiredForAdd         = ($stages.Count -gt 0)
            isApprovalRequiredForUpdate      = ($stages.Count -gt 0)
            isRequestorJustificationRequired = $justification
            stages                           = $stages
        }
        accessPackage           = @{ id = $AccessPackageId }
    }

    $rv = Get-EmProp $Policy 'accessReview'
    if ($rv) {
        $start = [datetime]::ParseExact([string]$rv.startDate, 'yyyy-MM-dd', $null)
        $fbr = Get-EmProp $rv 'fallbackReviewer'
        $body.reviewSettings = @{
            isEnabled                       = $true
            expirationBehavior              = $rv.onNoResponse
            isRecommendationEnabled         = $true
            isReviewerJustificationRequired = $true
            isSelfReview                    = $false
            primaryReviewers                = @(ConvertTo-EmSubjectSet -Reference $rv.reviewer -Resolve $Resolve)
            fallbackReviewers               = @(if ($fbr) { ConvertTo-EmSubjectSet -Reference $fbr -Resolve $Resolve })
            schedule                        = @{
                startDateTime = $start.ToString('yyyy-MM-ddT08:00:00Z')
                expiration    = @{ type = 'afterDuration'; duration = 'P{0}D' -f [int]$rv.durationDays }
                recurrence    = @{
                    pattern = @{ type = 'absoluteMonthly'; interval = $script:Recurrence[$rv.recurrence]; dayOfMonth = $start.Day }
                    range   = @{ type = 'noEnd'; startDate = $start.ToString('yyyy-MM-dd') }
                }
            }
        }
    }
    else {
        $body.reviewSettings = @{ isEnabled = $false }
    }
    $body
}

function Get-EmPolicyFingerprint {
    <#
    .SYNOPSIS
        Returns a stable JSON string of the fields that define a policy. Accepts a body built by
        ConvertTo-EmPolicyBody or a policy read from Graph, so desired and current compare directly.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)]$Policy)

    $p = $Policy | ConvertTo-Json -Depth 20 | ConvertFrom-Json
    $subject = {
        param($s)
        $t = ([string](Get-EmProp $s '@odata.type')).Replace('#microsoft.graph.', '')
        $ids = @((Get-EmProp $s 'userId'), (Get-EmProp $s 'groupId'), (Get-EmProp $s 'managerLevel')) | Where-Object { $null -ne $_ }
        '{0}:{1}' -f $t, (@($ids) -join '')
    }
    $appr = Get-EmProp $p 'requestApprovalSettings'
    $rev = Get-EmProp $p 'reviewSettings'
    $sched = Get-EmProp $rev 'schedule'
    $pattern = Get-EmProp (Get-EmProp $sched 'recurrence') 'pattern'

    $fp = [ordered]@{
        scope         = Get-EmProp $p 'allowedTargetScope'
        targets       = @(@(Get-EmProp $p 'specificAllowedTargets' @()) | ForEach-Object { & $subject $_ } | Sort-Object)
        expiration    = Get-EmProp (Get-EmProp $p 'expiration') 'duration'
        justification = [bool](Get-EmProp $appr 'isRequestorJustificationRequired' $false)
        stages        = @(@(Get-EmProp $appr 'stages' @()) | ForEach-Object {
                '{0}|{1}|{2}' -f (Get-EmProp $_ 'durationBeforeAutomaticDenial'),
                (@(@(Get-EmProp $_ 'primaryApprovers' @()) | ForEach-Object { & $subject $_ }) -join ','),
                (@(@(Get-EmProp $_ 'fallbackPrimaryApprovers' @()) | ForEach-Object { & $subject $_ }) -join ',')
            })
        review        = if ([bool](Get-EmProp $rev 'isEnabled' $false)) {
            '{0}|{1}|{2}|{3}|{4}' -f (Get-EmProp $rev 'expirationBehavior'),
            (Get-EmProp $pattern 'interval'),
            (Get-EmProp (Get-EmProp $sched 'expiration') 'duration'),
            (@(@(Get-EmProp $rev 'primaryReviewers' @()) | ForEach-Object { & $subject $_ }) -join ','),
            (@(@(Get-EmProp $rev 'fallbackReviewers' @()) | ForEach-Object { & $subject $_ }) -join ',')
        }
        else { 'disabled' }
    }
    $fp | ConvertTo-Json -Depth 5 -Compress
}

function Sync-EmCatalog {
    <#
    .SYNOPSIS
        Plans or applies one catalog configuration. Returns one change record per object.

    .EXAMPLE
        Sync-EmCatalog -Config $config -Mode Plan
        Sync-EmCatalog -Config $config -Mode Apply -WhatIf
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory)]$Config,
        [ValidateSet('Plan', 'Apply')][string]$Mode = 'Plan'
    )

    $problems = Test-EmConfig -Config $Config
    if ($problems.Count) { throw "Configuration is not valid:`n - $($problems -join "`n - ")" }

    $apply = $Mode -eq 'Apply'
    $changes = [System.Collections.Generic.List[object]]::new()
    $resolve = { param($ref) Resolve-EmPrincipal -Reference $ref }
    function Add-EmChange([string]$Kind, [string]$Name, [string]$Action, [string]$Detail = '') {
        $changes.Add([pscustomobject]@{ Kind = $Kind; Name = $Name; Action = $Action; Detail = $Detail })
        # Live progress, so an operator can follow (or safely interrupt) a long Apply.
        $colour = @{ Create = 'Green'; Update = 'Yellow'; Failed = 'Red'; Unmanaged = 'DarkYellow' }[$Action]
        if (-not $colour) { $colour = 'Gray' }
        Write-Host ('  {0,-9} {1,-13} {2}' -f $Action, $Kind, $Name) -ForegroundColor $colour
    }
    function Confirm-EmWrite([string]$Target, [string]$Action) {
        $apply -and $PSCmdlet.ShouldProcess($Target, $Action)
    }

    # ---------- pre-flight: resolve every group and user before any write ----------
    $refs = [System.Collections.Generic.HashSet[string]]::new()
    foreach ($r in $Config.resources) { [void]$refs.Add("group:$($r.displayName)") }
    foreach ($ap in $Config.accessPackages) {
        foreach ($p in $ap.policies) {
            foreach ($g in @(Get-EmProp $p.targets 'groups' @())) { [void]$refs.Add("group:$g") }
            foreach ($st in @(Get-EmProp $p 'approvalStages' @())) {
                foreach ($x in @($st.approver, (Get-EmProp $st 'fallback'))) { if ($x -and $x -ne 'manager') { [void]$refs.Add($x) } }
            }
            $rv = Get-EmProp $p 'accessReview'
            foreach ($x in @((Get-EmProp $rv 'reviewer'), (Get-EmProp $rv 'fallbackReviewer'))) { if ($x -and $x -ne 'manager') { [void]$refs.Add($x) } }
        }
    }
    $unresolved = @(foreach ($ref in $refs) { try { Resolve-EmPrincipal -Reference $ref | Out-Null } catch { "${ref}: $($_.Exception.Message)" } })
    if ($unresolved.Count) { throw "Pre-flight failed, no change was made. Unresolved references:`n - $($unresolved -join "`n - ")" }

    try {

        # ---------- catalog ----------
        $cat = $Config.catalog
        $existingCat = @(Invoke-EmGraph -Uri ("$script:EmBase/catalogs?`$filter=displayName eq '{0}'" -f (ConvertTo-EmODataString $cat.displayName)))
        $catalogId = $null
        if ($existingCat.Count -eq 0) {
            Add-EmChange 'Catalog' $cat.displayName 'Create'
            if (Confirm-EmWrite $cat.displayName 'Create catalog') {
                $catalogId = (Invoke-EmGraph -Method POST -Uri "$script:EmBase/catalogs" -Body @{
                        displayName = $cat.displayName; description = (Get-EmProp $cat 'description' ''); isExternallyVisible = [bool](Get-EmProp $cat 'isExternallyVisible' $false)
                    }).id
            }
        }
        else {
            $catalogId = $existingCat[0].id
            Add-EmChange 'Catalog' $cat.displayName 'NoChange'
        }

        # ---------- resources ----------
        $groupIds = @{}
        foreach ($r in $Config.resources) { $groupIds[$r.key] = Resolve-EmPrincipal -Reference "group:$($r.displayName)" }
        $catalogResources = if ($catalogId) { @(Invoke-EmGraph -Uri "$script:EmBase/catalogs/$catalogId/resources") } else { @() }
        $resourceIds = @{}
        foreach ($r in $Config.resources) {
            $match = @($catalogResources | Where-Object { $_.originId -eq $groupIds[$r.key] })
            if ($match.Count) { $resourceIds[$r.key] = $match[0].id; Add-EmChange 'Resource' $r.displayName 'NoChange'; continue }
            Add-EmChange 'Resource' $r.displayName 'Create' 'Add group to catalog'
            if ($catalogId -and (Confirm-EmWrite $r.displayName 'Add group to catalog')) {
                Invoke-EmGraph -Method POST -Uri "$script:EmBase/resourceRequests" -Body @{
                    requestType = 'adminAdd'
                    resource    = @{ originId = $groupIds[$r.key]; originSystem = 'AadGroup' }
                    catalog     = @{ id = $catalogId }
                } | Out-Null
                for ($i = 0; $i -lt 12 -and -not $resourceIds.ContainsKey($r.key); $i++) {
                    Start-Sleep -Seconds 5
                    $added = @(Invoke-EmGraph -Uri "$script:EmBase/catalogs/$catalogId/resources") | Where-Object { $_.originId -eq $groupIds[$r.key] }
                    if ($added) { $resourceIds[$r.key] = @($added)[0].id }
                }
                if (-not $resourceIds.ContainsKey($r.key)) { throw "Group '$($r.displayName)' did not appear in the catalog within 60 seconds." }
            }
        }

        # ---------- access packages, role scopes, policies ----------
        $existingPackages = if ($catalogId) { @(Invoke-EmGraph -Uri "$script:EmBase/catalogs/$catalogId/accessPackages") } else { @() }
        $packageIds = @{}
        foreach ($ap in $Config.accessPackages) {
            $current = @($existingPackages | Where-Object displayName -eq $ap.displayName)
            $apId = $null
            $desc = Get-EmProp $ap 'description' ''
            $hidden = [bool](Get-EmProp $ap 'isHidden' $false)
            if ($current.Count -eq 0) {
                Add-EmChange 'AccessPackage' $ap.displayName 'Create'
                if ($catalogId -and (Confirm-EmWrite $ap.displayName 'Create access package')) {
                    $apId = (Invoke-EmGraph -Method POST -Uri "$script:EmBase/accessPackages" -Body @{
                            displayName = $ap.displayName; description = $desc; isHidden = $hidden; catalog = @{ id = $catalogId }
                        }).id
                }
            }
            else {
                $apId = $current[0].id
                $diff = @()
                if ((Get-EmProp $current[0] 'description' '') -ne $desc) { $diff += 'description' }
                if ([bool](Get-EmProp $current[0] 'isHidden' $false) -ne $hidden) { $diff += 'isHidden' }
                if ($diff) {
                    Add-EmChange 'AccessPackage' $ap.displayName 'Update' ($diff -join ', ')
                    if (Confirm-EmWrite $ap.displayName 'Update access package') {
                        Invoke-EmGraph -Method PATCH -Uri "$script:EmBase/accessPackages/$apId" -Body @{ description = $desc; isHidden = $hidden } | Out-Null
                    }
                }
                else { Add-EmChange 'AccessPackage' $ap.displayName 'NoChange' }
            }
            if ($apId) { $packageIds[$ap.displayName] = $apId }

            # role scopes
            $currentScopes = @()
            if ($apId -and $current.Count) {
                $full = Invoke-EmGraph -Uri "$script:EmBase/accessPackages/$apId`?`$expand=resourceRoleScopes(`$expand=role,scope)"
                $currentScopes = @(@(Get-EmProp $full 'resourceRoleScopes' @()) | ForEach-Object { $_.role.originId })
            }
            foreach ($rr in $ap.resourceRoles) {
                $gid = $groupIds[$rr.resource]
                $originId = '{0}_{1}' -f $rr.role, $gid
                $name = '{0} / {1} {2}' -f $ap.displayName, $rr.resource, $rr.role
                if ($currentScopes -contains $originId) { Add-EmChange 'RoleScope' $name 'NoChange'; continue }
                Add-EmChange 'RoleScope' $name 'Create'
                if ($apId -and $resourceIds.ContainsKey($rr.resource) -and (Confirm-EmWrite $name 'Add resource role')) {
                    $filter = "(originSystem eq 'AadGroup' and resource/id eq '{0}')" -f $resourceIds[$rr.resource]
                    $role = $null
                    for ($i = 0; $i -lt 12 -and -not $role; $i++) {
                        # Roles of a group just added to the catalog can take a few seconds to appear.
                        if ($i) { Start-Sleep -Seconds 5 }
                        $role = @(Invoke-EmGraph -Uri "$script:EmBase/catalogs/$catalogId/resourceRoles?`$filter=$filter&`$expand=resource") |
                            Where-Object originId -eq $originId | Select-Object -First 1
                    }
                    if (-not $role) { throw "Role '$($rr.role)' not found for resource '$($rr.resource)' after 60 seconds." }
                    Invoke-EmGraph -Method POST -Uri "$script:EmBase/accessPackages/$apId/resourceRoleScopes" -Body @{
                        role  = @{ id = $role.id; originId = $originId; originSystem = 'AadGroup'; resource = @{ id = $resourceIds[$rr.resource]; originId = $gid; originSystem = 'AadGroup' } }
                        scope = @{ originId = $gid; originSystem = 'AadGroup'; isRootScope = $true }
                    } | Out-Null
                }
            }

            # policies
            $currentPolicies = if ($apId -and $current.Count) {
                @(Invoke-EmGraph -Uri "$script:EmBase/assignmentPolicies?`$filter=accessPackage/id eq '$apId'&`$expand=accessPackage")
            }
            else { @() }
            foreach ($p in $ap.policies) {
                $name = '{0} / {1}' -f $ap.displayName, $p.displayName
                $body = ConvertTo-EmPolicyBody -Policy $p -AccessPackageId ($apId ?? 'pending') -Resolve $resolve
                $existingPolicy = @($currentPolicies | Where-Object displayName -eq $p.displayName)
                if ($existingPolicy.Count -eq 0) {
                    Add-EmChange 'Policy' $name 'Create'
                    if ($apId -and (Confirm-EmWrite $name 'Create assignment policy')) {
                        Invoke-EmGraph -Method POST -Uri "$script:EmBase/assignmentPolicies" -Body $body | Out-Null
                    }
                    continue
                }
                $want = Get-EmPolicyFingerprint -Policy $body
                $have = Get-EmPolicyFingerprint -Policy $existingPolicy[0]
                if ($want -eq $have) { Add-EmChange 'Policy' $name 'NoChange'; continue }
                Add-EmChange 'Policy' $name 'Update' "tenant: $have | file: $want"
                if (Confirm-EmWrite $name 'Replace assignment policy') {
                    $body.id = $existingPolicy[0].id
                    Invoke-EmGraph -Method PUT -Uri "$script:EmBase/assignmentPolicies/$($existingPolicy[0].id)" -Body $body | Out-Null
                }
            }
            foreach ($extra in @($currentPolicies | Where-Object { $_.displayName -notin @($ap.policies.displayName) })) {
                Add-EmChange 'Policy' ('{0} / {1}' -f $ap.displayName, $extra.displayName) 'Unmanaged' 'In the tenant, not in the file. Not deleted.'
            }
        }
        foreach ($extra in @($existingPackages | Where-Object { $_.displayName -notin @($Config.accessPackages.displayName) })) {
            Add-EmChange 'AccessPackage' $extra.displayName 'Unmanaged' 'In the tenant, not in the file. Not deleted.'
        }

        # ---------- incompatible packages (second pass, all packages exist by now) ----------
        foreach ($ap in $Config.accessPackages) {
            $apId = $packageIds[$ap.displayName]
            $currentInc = if ($apId) { @(@(Invoke-EmGraph -Uri "$script:EmBase/accessPackages/$apId/incompatibleAccessPackages") | ForEach-Object displayName) } else { @() }
            foreach ($inc in @(Get-EmProp $ap 'incompatibleWith' @())) {
                $name = '{0} x {1}' -f $ap.displayName, $inc
                if ($currentInc -contains $inc) { Add-EmChange 'Incompatible' $name 'NoChange'; continue }
                Add-EmChange 'Incompatible' $name 'Create'
                if ($apId -and $packageIds.ContainsKey($inc) -and (Confirm-EmWrite $name 'Mark packages incompatible')) {
                    Invoke-EmGraph -Method POST -Uri "$script:EmBase/accessPackages/$apId/incompatibleAccessPackages/`$ref" -Body @{
                        '@odata.id' = "$script:GraphBase/$script:EmBase/accessPackages/$($packageIds[$inc])"
                    } | Out-Null
                }
            }
        }

    }
    catch {
        # Stop at the first failed write. Everything before it is in place and the record says where it
        # stopped; a re-run converges because every step checks the tenant before writing.
        Add-EmChange 'Run' 'Stopped' 'Failed' $_.Exception.Message
    }

    $changes.ToArray()
}

Export-ModuleMember -Function Test-EmConfig, ConvertTo-EmPolicyBody, Get-EmPolicyFingerprint, Resolve-EmPrincipal, Sync-EmCatalog, Invoke-EmGraph, Clear-EmPrincipalCache, Import-EmConfig
