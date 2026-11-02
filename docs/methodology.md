# Methodology

How a Copilot security engagement runs, from first diagnostic to enforced controls. The same pattern applies to every workstream.

## 1. Principles

| Principle | What it means in practice |
|---|---|
| Data before AI | Copilot respects existing permissions. It does not create oversharing, it reveals it. Fix exposure and classification first. |
| Smallest blast radius first | Every control starts on a pilot group (ring 0), then a pilot department (ring 1), then everyone (ring 2). |
| Simulate, then decide | DLP and agent rules run in simulation or measurement mode first. Enforcement is decided on real numbers. |
| The client owns the classification | The consultant designs the taxonomy and the mechanics. What is "Confidential" is a business decision. |
| Configured is not verified | A setting counts only after it has been read back from the tenant (PowerShell or portal), not when the save button worked. |
| Escalate only what matters | Changes without user impact are made and logged. Decisions with user or business impact go to the sponsor with a recommendation. |

## 2. Phases

```
Phase 0  Diagnostic      What can Copilot see? What is unprotected? What do agents cost?
Phase 1  Foundations     Labels (WS1), web grounding (WS5), agent and connector baseline (WS4)
Phase 2  Protection      DLP in simulation (WS2), oversharing remediation (WS3), shadow AI discovery (WS6)
Phase 3  Enforcement     Decision gates, enforcement by ring, capacity caps (WS7)
Run      Operate         Monthly Secure Score snapshot (WS8), inventory delta (WS3), cost review (WS7), agent review (WS4)
```

## 3. Rollout rings

| Ring | Scope | Exit criteria |
|---|---|---|
| 0 | One or two named pilot accounts, including a test account | Control behaves as designed, read back from the tenant, no false positive on test cases |
| 1 | A pilot department, ideally one that handles sensitive data | Simulation volume reviewed with the sponsor, user communication sent, support briefed |
| 2 | All users | Sponsor sign-off recorded, rollback tested |

Some locations cannot be scoped by group (for example the SharePoint location in DLP applies to sites, not users). Document those cases explicitly as tenant-wide from day one.

## 4. Decision gates

A decision gate is a short written proposal to the sponsor with: the finding, the numbers from simulation, the options, the recommended option, user impact and rollback. Typical gates:

1. Enforce the Copilot block on the "Confidential" level, or keep it in measurement mode.
2. Move the default label from "Internal" to "Confidential".
3. Block an AI app discovered by shadow AI discovery.
4. Allocate Copilot Credits capacity and set a cap per environment.
5. Accept a Secure Score recommendation as a risk instead of remediating it.

## 5. Evidence trail

Every engagement keeps:

- A **change log** (`04-secure-score-governance/change-log-template.csv` format): date, control, before, after, scope, user impact, rollback, who decided.
- **Read-back output** from each `Test-*` script, stored with the date.
- **Simulation reports** used for each decision gate.
- An **exception register** for any exclusion from a protective control (who, why, residual risk, review date).

This is what an auditor, a FINMA review or an internal control function will ask for. It is also what makes the engagement handover-ready.

## 6. Roles (RACI summary)

| Activity | Consultant | Client IT | Sponsor | Business owners |
|---|---|---|---|---|
| Diagnostic and design | R / A | C | I | C |
| Taxonomy content (what is confidential) | C | C | A | R |
| Configuration in pilot | R | C | I | I |
| Enforcement decision | C | C | A / R | C |
| Run and monthly review | R (if managed service) | R | I | I |
