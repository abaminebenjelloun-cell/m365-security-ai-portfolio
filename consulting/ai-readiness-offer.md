# AI readiness method

**Problem:** organisations want Copilot and agents but their data is not ready. Nobody knows what Copilot will see, nothing is classified, and agents appear without owners. AI projects stall or leak data.

Answer: a three-phase engagement that can be sold on its own. A full data protection programme is the logical follow-up, not a prerequisite.

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

Output: short report with the exposure picture, a prioritised action list and the licence prerequisites.

## Phase 2: Correction

- Close or restrict overexposed sites, clean obsolete content, assign owners.
- Deploy the four-level taxonomy (WS1) to a pilot, then broadly.
- Temporary measures where needed (Restricted Content Discovery, Restricted SharePoint Search), presented as temporary.

Output: delta report of exposure before and after (WS3 `Compare-InventorySnapshots.ps1`).

## Phase 3: Protection

- DLP for Microsoft 365 Copilot and Copilot Chat, external sharing DLP (WS2).
- Web grounding decision (WS5), governance of other AI tools (WS6).
- Agent baseline and capacity caps (WS4, WS7).
- Usage and cost monitoring as a run service (WS7, WS8).

## AI governance framework

Technical controls answer "can this data reach the AI". Clients also need "should we use AI for this, and who decides". A light framework is added on request:

| Element | Content |
|---|---|
| AI acceptable use policy | What employees may and may not do with AI tools, approved tools, data rules (links to WS1, WS6) |
| Use case register and risk classification | Every AI use case with owner, data, autonomy level, impact on people; higher risk cases need more review (links to the agent register in 02) |
| Roles | Sponsor, AI governance board or owner, data protection officer, business owners |
| Regulatory screening | revDSG for personal data. EU AI Act exposure for Swiss organisations whose AI systems or outputs are used in the EU. Screening is done with legal counsel, not by the consultant |
| Management system (optional) | ISO/IEC 42001 as the reference structure for organisations that want a certifiable AI management system |

## Adoption through AI champions

Once the data is protected, an [AI champions programme](ai-champions-programme.md) trains employees in each department to get colleagues using Copilot daily, within the rules (labels, approved tools, the agent request process). Success is measured on active users against licences assigned. Champions feed governance with feedback and new use cases.

## Prerequisites checked before selling

| Capability | Typical licence requirement (verify per tenant) |
|---|---|
| Sensitivity labels with encryption, DLP for Exchange, SharePoint, OneDrive | Microsoft 365 E3 or equivalent |
| DLP for Microsoft 365 Copilot, DSPM for AI, auto-labelling | Microsoft 365 E5, or E5 Compliance / Information Protection add-on |
| Defender for Cloud Apps discovery | Microsoft 365 E5 or Defender for Cloud Apps standalone |
| Agent 365 registry and lifecycle | Agent 365 per-user licence or Microsoft 365 E7 |

Licensing changes often. Confirm against current Microsoft licensing guidance before any proposal.

## Positioning

| Entry offer | Core offer | Follow-up offers |
|---|---|---|
| Flash assessment ([assessment-method.md](assessment-method.md)) | AI readiness (this page) | AI champions programme, agent governance (WS4), FinOps for AI (WS7), managed run (WS8) |
