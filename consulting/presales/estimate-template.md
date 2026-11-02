# Estimate template: AI readiness and first agent

Effort in person-days. Three sizes so the client sees what drives the price. Figures below are a **template structure with placeholder ranges**, to be adjusted per tenant after the discovery workshop. No rates in this repository.

## Sizing drivers

| Driver | Small | Medium | Large |
|---|---|---|---|
| Users | < 300 | 300 to 2,000 | > 2,000 |
| SharePoint sites | < 200 | 200 to 2,000 | > 2,000 |
| Existing labels and DLP | Some | None | None, plus legacy |
| Regulated (FINMA or health) | No | Partly | Yes |
| Agents already in the tenant | < 10 | 10 to 100 | > 100 |

## Work breakdown

| Phase | Activities | S | M | L |
|---|---|---|---|---|
| Discovery | Workshop, licence review, readiness checklist | 1 | 1.5 | 2 |
| Diagnostic | Inventory and exposure (WS3), label and DLP coverage, shadow AI (WS6), agent inventory (WS4), capacity view (WS7) | 2 | 4 | 6 |
| Correction | Taxonomy to pilot (WS1), oversharing remediation support with site owners, temporary restrictions | 2 | 5 | 10 |
| Protection | DLP for Copilot and external sharing in simulation (WS2), web grounding (WS5), agent baseline and data policy (WS4), capacity caps (WS7) | 2 | 4 | 6 |
| Decision gates and enforcement | Simulation review, sponsor decisions, enforcement by ring | 1 | 2 | 3 |
| First agent | Design, build, evaluation set, fixes, publishing to pilot (05) | 3 | 5 | 8 |
| Documentation and handover | Change log, runbooks, read-back evidence, training of IT | 1 | 2 | 3 |
| Project management | Steering, reporting | 10% | 10% | 10% |

## Assumptions to state in every estimate

- Licences required for each feature are in place before the phase starts.
- Site owners are available for remediation; the client owns the classification of its content.
- Simulation periods (two to four weeks) are elapsed time, not effort.
- Preview features are excluded from commitments unless stated.

## Exclusions

- Legal interpretation (revDSG, FINMA, contracts)
- Remediation of individual files beyond the agreed sites
- Custom development outside Microsoft 365 and Power Platform (for example Foundry), quoted separately
