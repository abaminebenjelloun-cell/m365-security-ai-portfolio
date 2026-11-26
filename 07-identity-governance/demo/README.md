# Lab setup: run the Entitlement Management build end to end

Everything here targets a **lab tenant** with synthetic users. Nothing is meant for a production tenant.

## 1. Licence

Entitlement Management needs Microsoft Entra ID P2 or Microsoft Entra ID Governance ([licensing](https://learn.microsoft.com/entra/id-governance/licensing-fundamentals)).
In an empty tenant: Microsoft 365 admin center > Billing > Purchase services > search "Microsoft Entra ID P2" > Details > Start free trial.
An ID Governance trial needs P1 or P2 already in the tenant. Licences can take a few minutes to show in the Entra admin center.

## 2. Seed the tenant

```powershell
Connect-MgGraph -UseDeviceCode -Scopes 'User.ReadWrite.All','Group.ReadWrite.All','Organization.Read.All','Application.ReadWrite.All','AppRoleAssignment.ReadWrite.All'
./07-identity-governance/demo/Initialize-DemoTenant.ps1
```

Creates 7 users (with managers, one deliberately without), the 8 groups the Finance catalog uses, memberships, licences, and the app registration the pipeline uses (Graph application permissions `EntitlementManagement.ReadWrite.All`, `Group.Read.All`, `User.Read.All`, 30-day secret shown once). Idempotent.

## 3. Deploy from a workstation

```powershell
Disconnect-MgGraph
Connect-MgGraph -UseDeviceCode -Scopes 'EntitlementManagement.ReadWrite.All','Group.Read.All','User.Read.All'
$cfg = './07-identity-governance/config/catalog-finance.json'
./07-identity-governance/Deploy-EntitlementManagement.ps1 -ConfigPath $cfg -Mode Plan      # 22 x Create
./07-identity-governance/Deploy-EntitlementManagement.ps1 -ConfigPath $cfg -Mode Apply
./07-identity-governance/Deploy-EntitlementManagement.ps1 -ConfigPath $cfg -Mode Plan      # 22 x NoChange
```

## 4. Azure DevOps

Use [pipelines/azure-pipelines-demo.yml](../pipelines/azure-pipelines-demo.yml): self-hosted agent, variable group `entra-demo` (TenantId, TenantDomain, ClientId, ClientSecret as secret), environment `entra-governance-demo` with an Approvals check. A new organisation has no Microsoft-hosted parallelism until billing is linked to an Azure subscription ([details](https://learn.microsoft.com/azure/devops/pipelines/licensing/concurrent-jobs)), so the demo runs on a self-hosted agent.

## What to show

| Capability | How |
|---|---|
| Configuration model | `config/catalog-finance.json`, `Test-EmConfig` errors on a broken file |
| End-to-end deployment | Plan, Apply, objects in Entra admin center > ID Governance > Entitlement management |
| Approvals and lifecycle | My Access (myaccess.microsoft.com): request as `fin.preparer`, approve as `fin.manager` then `finance.owner`; `fin.nomanager` goes to the fallback approvers; expiry and review schedule on each policy |
| Separation of duties | `fin.lead` holds Payments Approver, so the Payments Preparer request is blocked |
| Idempotency | Apply twice: the second run makes no write call |
| Drift | Change a policy expiry in the portal, Plan reports `Update`, Apply restores the file's value |
| Error handling and recovery | Missing group: pre-flight stops before any write. Interrupted run: re-run resumes. Throttling and transient errors: retried with backoff |
| Pipeline | Commit a change, Plan report as artifact, approval, Apply |
