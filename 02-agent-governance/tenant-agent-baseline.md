# Layer 1: tenant agent baseline

**Platform:** Microsoft 365 admin center (admin.microsoft.com) > Agents, and Copilot > Settings; Teams admin center for app setup policies.

Most of these controls need no extra licence. Export the inventory first so every later decision has a baseline.

| # | Control | Recommended value | Why |
|---|---|---|---|
| 1 | Export the agent inventory (Agents > All agents) | Export before any change, keep it dated | Baseline and audit evidence. Feeds `analyze_agent_inventory.py` |
| 2 | Allowed agent types | Microsoft agents and agents built by your organisation. Third-party publishers off by default, allowed case by case | Closes "unapproved agents" with one setting |
| 3 | Copilot Frontier (preview agents and features) | No access in production, or a named test group | Preview terms and changing behaviour are not acceptable for most Swiss regulated clients |
| 4 | Microsoft 365 Admin agent | Scope to named admins, or block | It is available to admin roles by default |
| 5 | Agent sharing | Restrict who can share agents org-wide | Prevents one maker's agent from appearing to everyone |
| 6 | User access to agents | All members except named exclusions, through a dynamic group (`New-AgentAccessGroup.ps1`) | Allows targeted exclusions without breaking access for everyone |
| 7 | Agent feedback sharing with Microsoft | Off unless the client accepts it | Data protection review |
| 8 | Teams app setup policies, Upload custom apps | Off for everyone except a developer group | Sideloading is how custom agents enter the tenant |
| 9 | Agent management rules (for example reject old publish requests) | Create, run on review | Keeps the approval queue clean |

## Field notes

- If an expected rule action (for example Block) is missing in a tenant, use what exists (reject publish requests, block individual agents from the inventory) and document the gap.
- Dynamic groups selecting "all enabled members" also include **functional and shared accounts**. List them in the hygiene findings.
- Differences between the registry (all agents, all platforms) and the Copilot Studio view (one environment) are a finding. An agent in one list only is in another environment, built with another tool, or a shadow agent.
