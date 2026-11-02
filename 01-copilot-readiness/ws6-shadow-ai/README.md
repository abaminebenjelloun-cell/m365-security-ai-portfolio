# WS6: Shadow AI

**Goal:** know which generative AI tools employees already use outside Microsoft 365 Copilot, and decide what to sanction, monitor or block.

**Platform:** Microsoft Defender portal > Cloud apps (Defender for Cloud Apps), Cloud Discovery.
**Verified on:** 2026-11-02.

## Discovery

| Step | Where | Notes |
|---|---|---|
| 1 | Cloud apps > Cloud Discovery | Use the Defender for Endpoint integration as the source (no log collector needed when devices are onboarded) |
| 2 | Filter by category **Generative AI** | Last 30 days |
| 3 | Export the app list | Users, devices, traffic uploaded, risk score |
| 4 | Check the Microsoft 365 app connector | It must collect activities, not only users and groups, otherwise the investigation view stays empty |

What a first discovery typically shows: Microsoft 365 Copilot Chat as the largest AI app by users, followed by public chat assistants with far fewer users but much more data uploaded. **Upload volume per user** is the number that matters, not the number of users.

## Decision tree

```
Is the app needed for a business process?
├── No  -> Unsanctioned (block on managed devices once enforcement is enabled), communicate the approved alternative
└── Yes
    ├── Is there an enterprise version with data protection terms the organisation accepts?
    │   ├── Yes -> Sanction, buy the enterprise version, scope by group
    │   └── No  -> Monitor, restrict data with Endpoint DLP (roadmap), re-evaluate quarterly
    └── Does Microsoft 365 Copilot Chat cover the use case?
        └── Yes -> Prefer Copilot Chat (stays inside the Microsoft 365 boundary), monitor the other app
```

## Guardrails

- **Tag nothing until the sponsor decides.** Tagging an app as unsanctioned can block it on managed devices if app access enforcement is enabled.
- Present the list with the approved alternative for each blocked app, otherwise usage just moves to personal devices.
- Data uploaded to an AI app is a revDSG question when it contains personal data: involve the data protection officer for apps processing personal data outside Switzerland.

## Output for the sponsor

A one-page table: app, users, data uploaded, enterprise version available, recommendation (sanction, monitor, block), and the alternative offered.
