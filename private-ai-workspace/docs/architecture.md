# Architecture

## Components

| Component | Runs where | Listens on | Purpose |
|---|---|---|---|
| Ollama | Laptop, Windows service at logon | `127.0.0.1:11434` only | Loads models on the GPU, serves the API |
| Odysseus | Laptop | Local port, reached only through the two remote paths | Workspace UI: chat, Compare, memory, RAG, deep research, agent, skills, scheduled tasks |
| Tailscale | Laptop and iPhone | Private tailnet | Phone access over HTTPS with Tailscale Serve |
| Cloudflare Tunnel (cloudflared) | Laptop, outbound connection only | No inbound port | Browser access behind a Cloudflare Access policy |

## Request flow

```
User (phone or browser)
  -> identity check (tailnet membership, or Cloudflare Access single-email policy)
  -> Odysseus (login + 2FA)
  -> Ollama on localhost
  -> GPU
```

Two identity layers sit in front of the workspace: network identity, then app login with 2FA. The model server has no network exposure.

## Design decisions

| Decision | Why | Rejected |
|---|---|---|
| Ollama bound to localhost | The model API has no authentication | Binding to 0.0.0.0 for convenience |
| Two remote paths | Tailscale for my devices; Cloudflare Access for a browser where I cannot install a client | Port forwarding on the router |
| Access policy before the tunnel | The service is never reachable without identity | Turning the tunnel on first and securing it after |
| Tailscale Funnel never used | Funnel publishes to the public internet | Funnel for simplicity |
| Agent tools locked by default | Retrieved content can carry instructions (prompt injection) | Enabling shell and file tools to "see what happens" |
| Four specialised models instead of one large one | Each fits fully in VRAM and is fast for its task | One 35B model that spills into RAM |
