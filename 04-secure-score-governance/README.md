# 04 · Secure Score governance (WS8)

**Goal:** raise Microsoft Secure Score to an agreed target without surprising users, and be able to defend every point in an audit (ADR-010).

**Platform:** Microsoft Defender portal (security.microsoft.com) > Exposure management > Secure Score, Intune, Entra ID, Exchange Online, Teams and SharePoint admin centers, Microsoft Graph for snapshots.

**Experience behind it:** a real programme on a client tenant, from a baseline of about 63% towards a 70% target agreed with the sponsor. The steps below are what was actually done, written without client names.

## Governance model

| Element | Rule |
|---|---|
| Target | Agreed with the sponsor, with a date, tracked as a score goal in Metrics and trends |
| Plan | Every recommendation in one checklist, sorted by **user impact** and difficulty, with a client validation column |
| Waves | Wave 1 none or low impact, wave 2 moderate with communication, wave 3 high with a pilot |
| Change log | Every change recorded: before, after, scope, impact, rollback, who decided ([change-log-template.csv](change-log-template.csv)) |
| Decisions instead of open items | Admin states **risk accepted**, **resolved through third party** or **alternate mitigation**, always with a written reason |
| Read-back | A change counts when the setting is read back and the score reflects it (refresh can take up to a day) |
| Monthly snapshot | `Get-SecureScoreSnapshot.ps1` exports the score, the gaps and the next wave candidates |

## What was done, step by step

### 1. Baseline and plan

| Step | Detail |
|---|---|
| Read three numbers, not one | Current score, licence ceiling and **achievable** score (current licences and risk acceptance). If the achievable score is below the target, the gap comes from accepted risks, not configuration |
| Build the plan | About 75 recommended actions in one workbook, each with points, user impact, effort, owner and status |
| Client validation | A dedicated tab where the client's IT approves or refuses each change before it is applied. Changes without user impact are applied and reported; changes with impact wait for a decision |
| Set the goal | Score goal in the Defender portal, so progress shows as a dated trend line in every recap |

### 2. Wave 1: quick wins without user impact

| Area | Change | Platform |
|---|---|---|
| Endpoint | EDR in block mode confirmed tenant-wide. One device not managed by the client (third-party antivirus, Defender in passive mode) marked **out of scope** with a reason instead of left open | Defender portal |
| Email | Outbound spam limit set to **restrict the sender** and notify IT | Defender portal |
| Email | **Mailbox auditing** switched on for every resource and system mailbox where it was off | Exchange Online PowerShell |
| Email | Third-party storage providers (Dropbox, Google Drive) disabled in Outlook on the web | Exchange Online PowerShell |
| Identity | Self-service password reset extended to **all users** | Entra admin center |
| Data | SharePoint **idle session sign-out** after one hour | SharePoint admin center |
| Endpoint | Antivirus scanning of **email and removable drives** added to the existing scan profile | Intune |

### 3. Wave 2: changes with user impact, communicated first

| Area | Change | Platform |
|---|---|---|
| Collaboration | Teams meetings: only **invited people bypass the lobby**, dial-in users no longer bypass it | Teams PowerShell |

### 4. Attack surface reduction (the hard part)

| Step | Detail |
|---|---|
| Analyse before changing | Two Intune profiles set ASR rules on overlapping devices. Checked **assignments including excluded groups** and the device groups behind them (Autopilot vs hybrid joined PCs) |
| Look at real impact | Advanced hunting on **ASR audited events** over 30 days to see what each rule would have blocked ([asr-audit-review.kql](asr-audit-review.kql)) |
| Conclusion | No real conflict: each profile covered a different device population. The planned redesign was dropped, saving effort and risk |
| Enforce | **Nine rules switched from Audit to Block** on the hybrid PCs with no impact seen in the audit period (credential theft from LSASS, Office child processes, Office code injection and executable content, obfuscated scripts, JavaScript and VBScript launching downloads, WMI persistence, Adobe Reader child processes, vulnerable signed drivers) |
| Handle a real block | A vendor firmware updater was blocked on one PC. Added a **per-rule, per-path exclusion** only, matching the one already used in the other profile |
| Keep in Audit, on purpose | Rules that would break business processes (legacy Excel macros, CAD applications started from Outlook, in-house tools with low prevalence) stay in Audit until the business owners decide or exclusions are agreed |
| Safety net | Seven-day hunting check on **Blocked** events after the switch, a user message to report blocks, and a one-step rollback (rule back to Audit) |

### 5. Email protection (Defender for Office 365)

| Change | Why |
|---|---|
| Safe Attachments from Dynamic Delivery to **Block** | Malicious attachments never reach the user |
| Anti-phishing **user impersonation protection** for executives and finance leads, plus own-domain protection and safety tips | Business email compromise targets these people first |
| **Uncovered accepted domains** added to the Safe Attachments, Safe Links and anti-phishing rules | Some group domains were outside every protection rule |

### 6. Device hardening

| Change | Why |
|---|---|
| Autoplay and AutoRun consolidated into **one profile assigned to all devices** (was split across user rings) | Full coverage, one place to manage |
| Duplicate older profiles kept 30 days for rollback, then removed | Clean configuration without risk |
| Finding: a static user group behind the "production" ring explained much of the partial device coverage | Fix the targeting, not only the setting |

### 7. Identity: Conditional Access in Report-only first

| Policy | Rule | Rollout |
|---|---|---|
| Admin sign-in frequency | Administrator roles re-authenticate every 4 hours, no persistent browser session; emergency access accounts excluded | Report-only, then On once no service account shows in the failures |
| Block Azure management for non-admins | All users except admin roles and emergency accounts blocked from Azure Resource Manager | Report-only for **7 days** (catches weekly or occasional users), then On |

### 8. Result and next steps

| Milestone | Score |
|---|---|
| Baseline | about 63% |
| After waves 1 and 2 | about 65% |
| After ASR, email protection and Autoplay (next sync) | about 68.5% (estimate) |
| After the two Conditional Access policies | about 69% (estimate) |
| Next: Windows hardening profile on 3 pilot PCs, then all | **above 70%** without any user-facing change |

Pending client decisions, presented with points and impact: impersonation action from Junk to Quarantine (who reviews the quarantine), Teams "only organizers present", and legacy mail flow rules that bypass spam filtering (each needs a business justification or removal).

Device points are estimates: they depend on how many PCs actually apply each setting. Every figure is re-checked on the Secure Score page after the sync.

## What this shows

- **Analysis before change:** the ASR redesign that looked necessary turned out not to be, which hunting data proved.
- **Business-aware enforcement:** blocking where the data says it is safe, auditing where it would break work, exclusions as narrow as possible.
- **Governance:** client validation, communication for user-facing changes, report-only before enforcement, rollback for each change, and every point traceable in the change log.

## Secure Score is not the CIS benchmark

Secure Score is Microsoft's view, weighted by Microsoft, and it moves when Microsoft adds controls. The CIS Microsoft 365 Foundations Benchmark is an external baseline used in the flash assessment. Report both, never merge them into one number.

## Traps

- **Check excluded groups** in Intune assignments, not only included ones: device-group exclusions on user-targeted assignments are a known source of coverage gaps.
- **Unmanaged devices** inflate endpoint gaps. Mark them out of scope with a reason.
- **One-toggle changes still need a communication** when users notice them (meeting lobby, sign-out timers).
- **Module conflicts:** Teams and Exchange Online PowerShell modules in the same session can clash. Use one window per module and device code sign-in (lessons L16, L17).

## Files

| File | Purpose |
|---|---|
| `Get-SecureScoreSnapshot.ps1` | Score, gap to target and next wave candidates through Microsoft Graph |
| `asr-audit-review.kql` | Advanced hunting: what ASR rules in Audit would block, and what rules in Block actually blocked |
| `change-log-template.csv` | Change log format, filled with anonymised examples from the programme |

## Run

```powershell
. ./common/M365Lab.Common.ps1
Connect-LabGraph -Scopes 'SecurityEvents.Read.All'
Assert-LabTenant -ExpectedTenantId <lab-tenant-guid>
./04-secure-score-governance/Get-SecureScoreSnapshot.ps1 -TargetPercent 70
```
