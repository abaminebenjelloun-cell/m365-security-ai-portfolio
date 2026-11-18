# MCP servers in Copilot Studio: governance note

**Last reviewed:** November 2026 on Microsoft Learn ("Add tools and resources from a Model Context Protocol (MCP) server to your agent").

## MCP in Copilot Studio

The Model Context Protocol lets an agent call tools and read resources exposed by an MCP server. In Copilot Studio, MCP servers are added from the agent's Tools page, under Model Context Protocol, from the available MCP connectors. Each server exposes a list of tools, all allowed by default. One server can bring many tools, and its tool list can change after the agent was approved.

## How existing controls apply

| Control | Effect on MCP |
|---|---|
| Power Platform data policy | Access goes through Power Platform connectors, so a data policy that blocks or classifies the connector also governs the MCP server and its tools |
| Custom connectors and custom MCP servers | Not governed until classified explicitly in the data policy. Inventory them first |
| Tool selection in the agent | Turn off **Allow all** and enable only the tools the use case needs. New tools added later on the server then stay off by default |
| Agent register | Record each MCP server and the enabled tools, and review them at each agent review |

## Rules

1. Classify every MCP connector explicitly in the data policy (business, non-business or blocked). Do not rely on the default group.
2. Preview MCP servers stay out of production environments.
3. Allow all is off for every MCP server in production agents; tools are enabled one by one.
4. Write actions exposed through MCP raise the agent's autonomy level (A2 or A3 in [agent-365-lifecycle.md](agent-365-lifecycle.md)) and need business owner approval.
5. Re-check the tool list of each MCP server at every agent review.

## Field observation

In a real, large agent inventory, a few agents already used MCP preview servers in production, and no data policy covered the custom MCP servers. Neither was visible without exporting and analysing the inventory. `analyze_agent_inventory.py` flags MCP usage; data policy coverage of each MCP connector is checked manually in the Power Platform admin center.
