# Demo script (10 minutes)

For a first client meeting or an interview. Business applications and agents first, then why the data work comes first. Every step has an offline file, so the demo works even without the lab tenant.

| Minute | Show (offline file) | Say |
|---|---|---|
| 0:00 | [README](../../README.md), journey diagram | "Assess, protect the data, drive adoption with champions, govern the agents, control the cost, and prove each step." |
| 1:00 | [05 field case](../../05-reference-agent-copilot-studio/README.md) and [agent design](../../05-reference-agent-copilot-studio/agent-design.md) | "I built a booking agent for a client; the data policy blocked it, I kept the policy and moved the use case to Copilot Chat. Since then I design agents under the rules from the start, like this HR policy agent: SharePoint knowledge only, user identity, no web, answers only, capped environment." |
| 2:30 | [05 evaluation test sets](../../05-reference-agent-copilot-studio/evaluation/) | "Twenty cases, one test set per persona because an evaluation runs as the signed-in user: permissions, Secret exclusion, prompt injection, four languages. Re-run after every change, and it can be triggered by API." Show results only if runs are recorded. |
| 4:00 | [Agent inventory analysis](../../02-agent-governance/sample-data/analysis_output_synthetic.txt) and [data policy design](../../02-agent-governance/power-platform-data-policy.md) | "Duplicates, admin-owned agents, uploaded files outside SharePoint permissions, MCP servers. Then the first data policy closes HTTP, anonymous channels and public web knowledge." |
| 5:30 | [Agent request and registry solution](../../02-agent-governance/agent-registry-solution.md) | "Requesting an agent must be easier than building one in secret: Dataverse, a model-driven app for IT, a canvas app in Teams, an approval flow." (Specification.) |
| 6:30 | [FinOps cost report (synthetic month)](../../03-finops-ai/sample-report/cost-report-synthetic.md) | "One polling flow accounts for more than half of consumption. The agents people value cost about a franc a day or less. A cap per environment makes this predictable." |
| 7:30 | [Labels](../../01-copilot-readiness/ws1-sensitivity-labels/README.md) and [Copilot DLP runbook](../../01-copilot-readiness/ws2-dlp/copilot-dlp-runbook.md) | "Why data first: Copilot shows people what they can already open. Secret has no EXTRACT right, so Copilot cannot use it; DLP is the second layer. Everything starts in simulation." |
| 8:30 | [AI champions programme](../ai-champions-programme.md) and [estimate template](estimate-template.md) | "Security makes Copilot safe, champions make it used: measured on active users against licences. And this is how the whole journey is scoped." |
| 9:30 | Questions | |
