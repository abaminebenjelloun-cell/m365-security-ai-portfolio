# 07 · Identity governance: Entitlement Management as code

A reference build for Microsoft Entra ID Governance access packages, driven by configuration. One JSON file describes a catalog: its resources, access packages, who can request, approval stages, expiry, access reviews and separation of duties. A PowerShell module applies it through Microsoft Graph v1.0, reports drift, and never deletes anything. An Azure DevOps pipeline runs plan, approval and apply.

Synthetic example: a Finance catalog with an analyst package, a payments preparer and a payments approver that can never be held together, and a time-boxed package for external auditors from connected organisations.

## Design principles

| Principle | How it shows up here |
|---|---|
| Native Entra first | Approvals, expiry, access reviews and incompatibility are built-in policy settings. No Logic Apps, no custom extensions, no scripts doing what a policy can do. Joiner, mover and leaver flows belong in Lifecycle Workflows. |
| Catalogs follow business ownership | One catalog per business area, so catalog owners and access package managers can be delegated to the business instead of IT. |
| Requesters scoped by group | `specificDirectoryUsers` limited to department groups; guests only through connected organisations. |
| Least privilege in time | Every assignment expires (30 to 365 days by risk), requestor justification required. |
| Approvals match risk | Manager for standard access, manager then resource owner for sensitive access, a control group for privileged access. Approver justification required, fallback approvers when the requestor has no manager. |
| Recurring review | Access reviews from monthly to annual by risk; access removed when reviewers do not respond. |
| Separation of duties | Incompatible access packages (Payments Preparer x Payments Approver), enforced by Entra at request time. |
| Configuration, not clicks | The file is the source of truth, reviewed in a pull request. Groups and users are referenced by name or UPN and resolved at run time, so no object IDs live in Git. |
| Safe by default | Plan is read only. Apply honours `-WhatIf`. Objects that exist in the tenant but not in the file are reported as `Unmanaged`, never deleted. |

## Files

| File | What it does |
|---|---|
| [config/catalog-finance.json](config/catalog-finance.json) | The catalog definition: 4 resources, 4 access packages, 4 policies |
| [EntitlementManagement.psm1](EntitlementManagement.psm1) | `Test-EmConfig`, `ConvertTo-EmPolicyBody`, `Get-EmPolicyFingerprint`, `Sync-EmCatalog` |
| [Deploy-EntitlementManagement.ps1](Deploy-EntitlementManagement.ps1) | Pre-check (file and tenant), Plan or Apply, JSON and Markdown report in `output/` |
| [tests/Invoke-OfflineTests.ps1](tests/Invoke-OfflineTests.ps1) | Runs the module against an in-memory fake of the Graph endpoints |
| [pipelines/azure-pipelines.yml](pipelines/azure-pipelines.yml) | Validate, Plan, approval gate, Apply, plus a weekday drift check |

## How a run works

```
catalog file -> Test-EmConfig -> Plan (read tenant, compare) -> report -> approval -> Apply -> Plan again = no change
```

Order of operations: catalog, catalog resources (groups added with an `adminAdd` resource request), access packages, resource role scopes, assignment policies, then incompatible packages in a second pass once every package exists.

Drift is detected per policy with a fingerprint of the fields that matter (target scope and groups, expiry, justification, every approval stage with its approvers and fallbacks, review recurrence, duration, reviewers and no-response behaviour), so a change made in the portal shows up as `Update` in the next plan.

## Run it

```powershell
# Offline, no tenant needed
pwsh ./07-identity-governance/tests/Invoke-OfflineTests.ps1

# Lab tenant (PowerShell 7, Microsoft.Graph.Authentication)
. ./common/M365Lab.Common.ps1
Connect-LabGraph -Scopes 'EntitlementManagement.Read.All','Group.Read.All','User.Read.All'
./07-identity-governance/Deploy-EntitlementManagement.ps1 -ConfigPath ./07-identity-governance/config/catalog-finance.json -Mode Plan -ExpectedTenantId <lab-tenant-guid>
./07-identity-governance/Deploy-EntitlementManagement.ps1 -ConfigPath ./07-identity-governance/config/catalog-finance.json -Mode Apply -ExpectedTenantId <lab-tenant-guid> -WhatIf
```

Permissions: `EntitlementManagement.ReadWrite.All`, `Group.Read.All`, `User.Read.All` (Plan needs only the read scopes). In the pipeline, a workload identity federation service connection with those Graph application permissions; no secrets.

## Status

| Content | Status |
|---|---|
| Configuration schema and validation | Done, covered by offline tests |
| Policy body builder and drift fingerprint | Done, covered by offline tests |
| Plan / Apply against the fake Graph endpoints | 23 offline checks pass: create, idempotent re-run, drift correction, unmanaged objects, WhatIf |
| Run against a real tenant | Not yet. Bodies follow the Graph v1.0 schema; first tenant run goes through Plan and `-WhatIf` before Apply |
| Terraform | Optional alternative for teams standardised on it: the `azuread` provider has `azuread_access_package*` resources. Kept out of this build to stay on one toolchain |

## Out of scope in this version

Application and SharePoint site resources (groups only), custom extensions, multi-catalog orchestration. The same pattern extends to them.

## References

- [What is entitlement management?](https://learn.microsoft.com/entra/id-governance/entitlement-management-overview)
- [Entitlement management API overview (Graph v1.0)](https://learn.microsoft.com/graph/api/resources/entitlementmanagement-overview)
- [accessPackageAssignmentPolicy resource type](https://learn.microsoft.com/graph/api/resources/accesspackageassignmentpolicy)
- [Separation of duties checks with incompatible access packages](https://learn.microsoft.com/entra/id-governance/entitlement-management-access-package-incompatible)
