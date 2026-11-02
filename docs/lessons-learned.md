# Lessons learned

Field notes from real Copilot, Power Platform and Microsoft 365 governance work. Each one cost time at least once. All are product behaviours, not client facts. Numbering is stable so other pages can reference a lesson.

## Copilot Studio, Power Platform and cost

| # | Lesson | Why it matters |
|---|---|---|
| L19 | A tenant without a Power Platform data policy lets **any user build an agent wired to any connector**, including HTTP and public web knowledge. | The first data policy is a quick, high-value win. |
| L20 | Capacity is allocated **per environment**. Without allocation, the first agent that consumes wins. | Dedicated, capped environments for heavy makers. |
| L21 | Agent flows bill **per action on every run, even when nothing happens**. A 5-minute schedule costs roughly 290 times a daily one for the same flow. | Cheap checks first, classic flows for polling, invoke the agent only when there is work. |
| L22 | Agent flow test runs from the designer do not bill agent flow actions. | Measure agent flow cost on real runs, not tests, and check the billing rules for other features. |
| L23 | Seeded AI Builder credits stop for new or renewed Power Platform licences from **1 November 2026**. | Inventory flows with AI actions before renewals and plan Copilot Credits capacity. |
| L24 | Prepaid capacity and pay-as-you-go have **different unit prices**. | Check which one the tenant uses before converting credits to money. A wrong rate silently distorts every figure. |

## Purview: sensitivity labels

| # | Lesson | Why it matters |
|---|---|---|
| L1 | **Copilot needs the `EXTRACT` usage right to ground on an encrypted item.** A label whose encryption removes `EXTRACT` keeps that content out of Copilot answers, even for users who can open it. Exception: the Rights Management owner (the person who applied the encryption) keeps full rights. | This is the cleanest way to define a "never in Copilot" level, with a DLP rule as second layer for the owner case. Keep `EXTRACT` on "Confidential" if Copilot must still work on it. Test with a user who did not label the document. |
| L2 | **When a user is in several label policies, they get the labels from all of them, but conflicting settings (default label, mandatory labelling) come from the highest-priority policy.** | Overlapping policies make the effective settings hard to predict. Prefer one policy that publishes every label a user needs, and use priority deliberately. |
| L3 | Label policies target **users and groups**, DLP targets **locations**. | Different scoping logic, different pilot groups. Plan both. |
| L4 | Pure (non mail-enabled) security groups cannot be used to scope label policies. | Use mail-enabled security groups, Microsoft 365 groups or distribution groups for pilots. |
| L5 | Access to a "Secret" label with admin-defined permissions for all users relies entirely on **SharePoint and OneDrive permissions**. | The oversharing workstream (WS3) becomes load-bearing for the label design. |
| L6 | Dynamic watermarking only works on supported Office versions. Older clients can get "access denied". | Test on Word desktop and Word for the web before rollout. |
| L7 | Enabling co-authoring for encrypted files is effectively one-way from the portal. | Treat it as a decision gate with written sign-off. |

## Purview: DLP

| # | Lesson | Why it matters |
|---|---|---|
| L8 | The **sensitivity label condition is unavailable** when the Teams chat and channel location is selected in the same policy. | Put Teams in a separate policy, or leave it out of label-based external sharing rules. |
| L9 | The **SharePoint location applies to sites, not users**. It cannot be scoped to a pilot group. | Document SharePoint rules as tenant-wide from day one, and keep them in simulation until reviewed. |
| L10 | The **Microsoft 365 Copilot and Copilot Chat** location can only be used in a custom policy, and selecting it disables the other locations. | Copilot DLP is always its own policy. |
| L11 | In Copilot DLP, a **sensitivity label condition and a sensitive information type condition cannot be in the same rule**. | One rule per condition type. |
| L12 | Copilot DLP changes can take **up to four hours** to apply. | Do not conclude a test failed after ten minutes. |
| L13 | Some Copilot DLP features are **preview** (for example blocking prompts that contain sensitive information types, and excluding emails from external senders). | Label them as preview in every client document and check tenant availability first. |

## Exchange Online protection policies

| # | Lesson | Why it matters |
|---|---|---|
| L14 | Anti-spam, anti-malware and anti-phishing protection is made of **two objects: a policy and a rule**. | The portal can create the policy and fail on the rule, leaving an orphaned policy that blocks re-creation with the same name. Always read both back. |
| L15 | Removal syntax differs: `-Force` for anti-spam and anti-malware policies, `-Confirm:$false` for anti-phishing. | Cleanup scripts need both. |

## PowerShell and identity (multi-tenant consultant life)

| # | Lesson | Why it matters |
|---|---|---|
| L16 | **Identity bleed:** the Windows Web Account Manager (WAM) silently reuses a cached account from another tenant. | Use device code flow, `-DisableWAM` where available, and always print the connected tenant ID before any change. See `common/M365Lab.Common.ps1`. |
| L17 | `ExchangeOnlineManagement` and `Microsoft.Graph` loaded in the same session can conflict on the authentication library. | One module family per PowerShell window. |
| L18 | On locked-down laptops (no local admin, Documents redirected to OneDrive), `Install-Module` scopes fail in surprising ways. | Use `Save-Module` to a local folder and import from there. Pin module versions that are known to work. |

## Delivery discipline

| # | Lesson | Why it matters |
|---|---|---|
| L25 | Never call something configured until it is **read back**. | Saves the embarrassing "it was in the deck but not in the tenant". |
| L26 | Every figure in a deliverable must be **traceable to a source file** and reconciled. Count distinct recommendations, not raw lines. | Numbers are what the client remembers, and what an auditor checks. |
| L27 | Re-enrolling a device as a first troubleshooting step **destroys forensic evidence**. | Quarantine the next affected device instead. |
