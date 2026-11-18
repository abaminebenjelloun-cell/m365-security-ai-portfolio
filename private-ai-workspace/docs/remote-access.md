# Remote access without open ports

## Phone: Tailscale Serve

| Setting | Value |
|---|---|
| Exposure | HTTPS inside my private tailnet only |
| Devices | My own, enrolled in the tailnet |
| Funnel | Never used (it publishes to the public internet) |

## Browser: Cloudflare Tunnel behind Cloudflare Access

| Setting | Value |
|---|---|
| Tunnel | `cloudflared` connects outbound; no inbound port on the router |
| Access policy | Allow one email identity, deny everything else |
| Order | Access application and policy created **before** the tunnel was switched on |

## Rules of use

- Personal and learning use only. No employer or client data is entered, from any device.
- Remote access reaches the workspace, never Ollama directly. The workspace has its own login and 2FA.

## Checks after any change

| Check | Expected |
|---|---|
| Open the public hostname in a private window, not signed in | Cloudflare Access login page, never the workspace |
| From a device outside the tailnet, try the tailnet address | Unreachable |
| Port scan of my public IP | No open service port |
| `netstat -ano` on the laptop for port 11434 | Bound to 127.0.0.1 only |
