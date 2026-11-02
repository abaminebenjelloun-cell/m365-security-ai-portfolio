# DLP test matrix

Run with `pilot.copilot` (in the pilot group) and `alice` (outside the pilot group) on the lab tenant. Record the date, the result and a screenshot reference. A test passes only when observed, not when expected.

## DLP for Copilot

| # | Test | Expected (simulation) | Expected (enforced) | Result | Date |
|---|---|---|---|---|---|
| C1 | Ask Copilot to summarise a **Secret** document the user can open | Match in simulation report | Content not used, policy message shown | | |
| C2 | Ask Copilot to summarise a **Confidential** document | Match logged (measurement) | Depends on decision gate | | |
| C3 | Ask Copilot to summarise an **Internal** document | No match | Summary returned | | |
| C4 | Prompt with a synthetic AHV number and a question needing the web | Match in simulation report | No web search performed | | |
| C5 | Ask Copilot about an email received from an external sender (preview) | Match in simulation report | Email not used | | |
| C6 | Same as C1 with `alice` (outside pilot) | No match | No match | | |

## External sharing DLP

| # | Test | Expected (simulation) | Expected (enforced) | Result | Date |
|---|---|---|---|---|---|
| E1 | Share a **Secret** file from OneDrive with an external guest | Policy tip, match logged | External access blocked, no override | | |
| E2 | Share a **Confidential** file externally | Policy tip, match logged | Blocked, override with justification possible | | |
| E3 | Email a **Confidential** document to an external address | Policy tip, match logged | Blocked unless justified | | |
| E4 | Share an **Internal** file with a synthetic IBAN externally | Incident report generated | Incident report, no block | | |
| E5 | Share a **Public** file externally | No match | Allowed | | |
| E6 | Share a Secret file **internally** | No match | Allowed | | |

## Decision gate input

After the simulation period, report per rule: number of matches, number of distinct users, top sites, false positives found, and the recommended mode.
