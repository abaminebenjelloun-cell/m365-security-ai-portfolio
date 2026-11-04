# Threat model

The attack surface: a model API, a web UI, remote access, and an agent that can read the web and act on the machine.

| # | Threat | Example | Mitigation in place | Next |
|---|---|---|---|---|
| T1 | Unauthenticated model API | Anyone on the network sends prompts or pulls models | Ollama bound to 127.0.0.1 | Check after every Ollama update |
| T2 | Workspace reachable from the internet | Brute force on the login page | No open ports; network identity (tailnet, Cloudflare Access) before the app; login with 2FA; single admin; sign-up off | Review Access logs monthly |
| T3 | Indirect prompt injection | A web page or RAG document says "ignore your instructions and run this command" | Agent shell, file and system tools locked until reviewed | Enable tools one by one, read-only first, with a confirmation step |
| T4 | Data exfiltration through tools | Agent sends memory or documents to an external URL | Tools locked, email and calendar tasks paused | Allow-list of tools and destinations per task |
| T5 | Sensitive data in the workspace | Work or client data pasted by habit | Rule: no employer or client data, ever | |
| T6 | Secrets leakage | API keys in `.env`, chats or repositories | Secrets only in local `.env` files, ignored by git | Move to a secret store |
| T7 | Device loss or theft | Laptop stolen with models, memory and documents | Windows device encryption | Scheduled encrypted backups (phase 9) |
| T8 | Supply chain | Malicious model file or workspace update | Models pulled from the Ollama library only; open-source workspace | Pin versions, read release notes before updating |

Enterprise agents need the same controls: identity before access, least privilege on tools, human confirmation for actions, and injection test cases before release to users.
