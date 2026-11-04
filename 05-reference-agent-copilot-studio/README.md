# 05 · Reference agent (Copilot Studio)

> **Status:** field case from a real client build (below). Reference agent designed with its evaluation set, **build on the lab tenant in progress**. The results table is filled from real evaluation runs only.

## Field case: a real agent meets governance

| | |
|---|---|
| Context | A client asked for a **booking agent** built in Copilot Studio |
| What happened | The agent was built, then **blocked by the client's Power Platform data policy**: a connector it needed was not allowed |
| Decision | **Did not weaken the policy** to make the agent work. Re-assessed the use case and moved it to **Microsoft 365 Copilot Chat with file attachments**, which met the need inside the existing controls |
| Why it matters | Governance is only credible if it also applies to your own build. The right question is not "how do I get around the control" but "which tool fits the need within it" (lesson L28) |

## Reference agent

A small agent **designed to be built under every rule in this portfolio**, to prove the governance works on a build and to show how an agent is evaluated before it reaches users.

## Use case

**HR Policy Assistant** for Contoso Fiduciaire SA (fictional). Employees ask questions about leave, expenses, remote work and onboarding. HR staff can also ask about the salary grid. Answers come only from the HR policies library in SharePoint, with a citation.

| Item | Choice | Why |
|---|---|---|
| Platform | Copilot Studio | Knowledge lives in Microsoft 365, users authenticate with Entra ID, governance is native (ADR-009) |
| Knowledge | SharePoint HR Policies library only, no uploaded files, no public websites | Permissions stay enforced (WS3), blocked public web knowledge (WS4) |
| Authentication | Microsoft Entra ID, the user's own identity | Users only get answers from documents they can open |
| Autonomy | A0, answers only (see 02 agent lifecycle) | No action without a human |
| Environment | Dedicated maker environment with a capped allocation | Cost isolated and predictable (WS7) |
| Publishing | Teams and Microsoft 365 Copilot, scoped to a security group | Not org-wide by default |

Full design: [agent-design.md](agent-design.md).

## How each governance layer applies

| Layer | Check on this agent |
|---|---|
| WS1 labels | The salary grid is Confidential (HR only), an investigation file is Secret: the agent must never use it |
| WS2 DLP | To verify: Microsoft Learn does not document DLP for Copilot coverage of Copilot Studio agents. Test case T16 checks the behaviour in simulation; the agent instructions forbid repeating personal identifiers either way |
| WS3 oversharing | The HR library is not reachable by everyone, confirmed in the inventory |
| WS4 agents | Registered in the agent register, connectors allowed by the data policy, owner and sponsor named |
| WS7 cost | Credits per answer measured during the evaluation runs, monthly budget set |

## Evaluation

The agent is tested with 20 cases covering grounded answers, permissions, labels, refusals, prompt injection and languages. An evaluation runs as the signed-in user, so there is **one test set per persona**: [employee](evaluation/test-set-employee.csv) (18 cases), [HR](evaluation/test-set-hr.csv) (1 case) and [HR lead](evaluation/test-set-hr-lead.csv) (1 case, Secret exclusion), each run while signed in as that persona. Runs use the **Evaluation** page of Copilot Studio (test sets, pass or fail per case with the reasoning, comparison between runs). Evaluations can also be triggered through the Power Platform API or a flow, which is the path to running them automatically after every change.

Results: [evaluation/results.md](evaluation/results.md).

## Build steps

1. Create the dedicated environment and allocate capacity (03-finops-ai).
2. Create the agent, add the SharePoint knowledge source, set instructions from `agent-design.md`.
3. Turn off general knowledge and web search for the agent.
4. Import each persona's test set and run it while signed in as that persona, record results.
5. Fix the failures (instructions, knowledge scope, topics), re-run, record the comparison.
6. Export the solution and unpack it into `solution/` for version control:
   ```
   pac solution export --name HRPolicyAssistant --path ./HRPolicyAssistant.zip
   pac solution unpack --zipfile ./HRPolicyAssistant.zip --folder ./05-reference-agent-copilot-studio/solution
   ```
7. Register the agent (02 register), publish to the pilot group.

## Next: the same use case on Microsoft Foundry

Rebuilt with Azure AI Search in Switzerland North, own retrieval tuning and an automated evaluation pipeline, to compare quality, control and cost with the Copilot Studio version.
