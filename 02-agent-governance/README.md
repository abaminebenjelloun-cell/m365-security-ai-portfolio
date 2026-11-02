# 02 · Agent governance (WS4)

Copilot Studio is available to every Microsoft 365 user. Without governance, a tenant ends up with hundreds of agents, duplicated, owned by admin accounts or by people who left, wired to any connector, and consuming shared capacity. This section governs agents at three layers (ADR-007).

**Experience behind it:** first Power Platform data policy on a tenant that had none, agent access restricted through a dynamic Entra group, analysis of an inventory of several hundred agents (duplicates, admin-owned agents, MCP preview servers, sensitive files uploaded as agent knowledge outside SharePoint permissions), Agent 365 hardening split into "no extra licence" and "licensed" layers, and a Power Automate governance guideline approved by the client.

**Last reviewed:** November 2026. Agent settings in the Microsoft 365 admin center moved several times in 2026: look for the closest equivalent if a label differs.

## The three layers

| Layer | Controls | Where | Licence |
|---|---|---|---|
| 1. Tenant agent baseline | Allowed agent types, third-party publishers, Frontier previews, sharing, user access to agents, sideloading | Microsoft 365 admin center > Agents, Copilot settings; Teams admin center | Included |
| 2. Build-time controls | Data policy for Copilot Studio connectors, who can author, environment strategy, capacity | Power Platform admin center | Included (capacity is paid) |
| 3. Lifecycle | Inventory, owner, sponsor, data, review date, block, retire | Agent 365 registry, M365 admin center > Agents, Power Platform inventory | Inventory included; Agent 365 registry and lifecycle at scale need Agent 365 |

## Files

| File | Purpose |
|---|---|
| [tenant-agent-baseline.md](tenant-agent-baseline.md) | Layer 1 checklist with recommended values and why |
| [power-platform-data-policy.md](power-platform-data-policy.md) | Layer 2: data policy design for Copilot Studio |
| `config/copilot-studio-data-policy.json` | The connectors the policy must block, as code |
| `Test-PowerPlatformDataPolicy.ps1` | Reads the tenant data policies back and checks the blocked connectors |
| `New-AgentAccessGroup.ps1` | Creates the dynamic Entra group used to scope who can use agents |
| [agent-365-lifecycle.md](agent-365-lifecycle.md) | Layer 3: lifecycle, Agent 365 licensing, review cadence |
| `agent-register-template.csv` | Register columns: owner, sponsor, data, permissions, autonomy, review date |
| `analyze_agent_inventory.py` | Analyses an agent inventory export: duplicates, ownership, inactivity, MCP, uploaded files |
| `sample-data/agent_inventory_synthetic.csv` | Synthetic inventory to run the analysis |
| [power-automate-governance.md](power-automate-governance.md) | Flow ownership, offboarding, unused flows, service account |
| [agent-registry-solution.md](agent-registry-solution.md) | Dataverse, model-driven and canvas apps, approval flows: the request and registry solution (build in progress) |
| [mcp-governance.md](mcp-governance.md) | How data policies and tool selection govern MCP servers in Copilot Studio |

## Run

```bash
python3 02-agent-governance/analyze_agent_inventory.py 02-agent-governance/sample-data/agent_inventory_synthetic.csv \
    --today 2026-11-02 --active-users 02-agent-governance/sample-data/active_users_synthetic.txt
# Expected output: sample-data/analysis_output_synthetic.txt
```

```powershell
# Power Platform data policy read-back (Windows PowerShell 5.1: the Power Apps admin module targets it)
Add-PowerAppsAccount
./02-agent-governance/Test-PowerPlatformDataPolicy.ps1 -ConfigPath ./02-agent-governance/config/copilot-studio-data-policy.json
```
