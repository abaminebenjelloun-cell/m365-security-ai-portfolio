# AI readiness method

**Problem:** organisations want Copilot and agents, but their data is not ready. Nobody knows what Copilot will be able to see, nothing is classified, and agents appear without owners. AI projects stall or create a leak.

**Answer:** a three-phase AI readiness engagement that can be sold on its own. A full data protection programme is the logical follow-up, not a prerequisite.

```
 1. Diagnostic            2. Correction                3. Protection
 What can AI see?    ->   Reduce exposure,        ->   Enforce and monitor
                          classify what matters
```

## Phase 1: Diagnostic

| Question | How it is answered | Workstream |
|---|---|---|
| What can Copilot and other AI tools see today? | SharePoint and OneDrive inventory with exposure flags, Purview DSPM for AI where licensed | WS3 |
| Which sensitive data is unprotected? | Sensitive information type detection, label coverage | WS1, WS2 |
| Which AI apps are already used? | Defender for Cloud Apps discovery, generative AI category | WS6 |
| Which agents exist, who owns them, what do they cost? | Agent inventory, Copilot Credits consumption | WS4, WS7 |
| Is the licence fit right? | Licence check (for example E5 vs E3 with a compliance add-on) | all |

**Output:** a short report with the exposure picture, a prioritised action list and the licence prerequisites.

## Phase 2: Correction

- Close or restrict overexposed sites, clean obsolete content, assign owners.
- Deploy the four-level taxonomy (WS1) to a pilot, then broadly.
- Temporary measures where needed (Restricted Content Discovery, Restricted SharePoint Search), clearly presented as temporary.

**Output:** delta report showing exposure before and after (WS3 `Compare-InventorySnapshots.ps1`).

## Phase 3: Protection

- DLP for Microsoft 365 Copilot and Copilot Chat, external sharing DLP (WS2).
- Web grounding decision (WS5), governance of other AI tools (WS6).
- Agent baseline and capacity caps (WS4, WS7).
- Usage and cost monitoring as a run service (WS7, WS8).

## Prerequisites checked before selling

| Capability | Typical licence requirement (verify per tenant) |
|---|---|
| Sensitivity labels with encryption, DLP for Exchange, SharePoint, OneDrive | Microsoft 365 E3 or equivalent |
| DLP for Microsoft 365 Copilot, DSPM for AI, auto-labelling | Microsoft 365 E5, or E5 Compliance / Information Protection add-on |
| Defender for Cloud Apps discovery | Microsoft 365 E5 or Defender for Cloud Apps standalone |
| Agent 365 registry and lifecycle | Agent 365 per-user licence or Microsoft 365 E7 |

Licensing changes often. Confirm against the current Microsoft licensing guidance before any proposal.

## Positioning

| Entry offer | Core offer | Follow-up offers |
|---|---|---|
| Flash assessment ([assessment-method.md](assessment-method.md)) | AI readiness (this page) | Agent governance (WS4), FinOps for AI (WS7), managed run (WS8) |
