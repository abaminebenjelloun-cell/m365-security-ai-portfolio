# 04 · Secure Score governance (WS8)

**Goal:** raise Microsoft Secure Score to an agreed target without surprising users, and be able to defend every point in an audit (ADR-010).

**Platform:** Microsoft Defender portal (security.microsoft.com) > Exposure management > Secure Score, and Microsoft Graph for snapshots.

**Experience behind it:** a programme to bring a client tenant to a 70% target, run in waves with a change log, explicit "out of scope" decisions for unmanaged devices, and a redesign item parked deliberately because two existing device policies conflicted.

## Governance model

| Element | Rule |
|---|---|
| Target | Agreed with the sponsor (for example 70%), with a date |
| Waves | Group recommendations by **user impact**: wave 1 none or low, wave 2 moderate with communication, wave 3 high with pilot |
| Change log | Every change recorded before, after, scope, impact, rollback, who decided ([change-log-template.csv](change-log-template.csv)) |
| Decisions instead of open items | Use the admin states **risk accepted**, **resolved through third party** or **resolved through alternate mitigation**, always with a written reason |
| Read-back | A change counts when the setting is read back and the score reflects it (the score refresh can take up to a day) |
| Monthly snapshot | `Get-SecureScoreSnapshot.ps1` exports the score, the gaps and the next wave candidates |

## Secure Score is not the CIS benchmark

Secure Score is Microsoft's view, weighted by Microsoft, and it moves when Microsoft adds controls. The CIS Microsoft 365 Foundations Benchmark is an external baseline used in the flash assessment. Report both, never merge them into one number.

## Traps

- **Conflicting device policies.** Two policies setting the same attack surface reduction rules to different values on overlapping device groups make the score and the real protection disagree. Consolidate before chasing points.
- **Unmanaged devices** inflate gaps for endpoint controls. Mark them out of scope with a reason rather than leaving them open.
- **Points with real user impact** (for example meeting lobby rules or sign-out timers) need a communication, even when the change is one toggle.

## Run

```powershell
. ./common/M365Lab.Common.ps1
Connect-LabGraph -Scopes 'SecurityEvents.Read.All'
Assert-LabTenant -ExpectedTenantId <lab-tenant-guid>
./04-secure-score-governance/Get-SecureScoreSnapshot.ps1 -TargetPercent 70
```
