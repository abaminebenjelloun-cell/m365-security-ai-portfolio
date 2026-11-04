# Private AI Workspace

A ChatGPT-class workspace on my laptop GPU: four open-weight models, retrieval, an agent and memory, reachable from my phone. No per-token cost, no subscription, no data leaving the machine. In parallel, I am building an LLM from scratch to learn how they work.

Personal project, outside work. **No employer or client data ever goes into it.**

---

## Why

- **Cost:** unlimited use on hardware I already own. The only cost is electricity.
- **Privacy:** prompts, documents, memory and email stay on my disk. Cloud features are off.
- **Understanding:** context budgets, retrieval, quantization, prompt injection and agent tool control are the same mechanics as in Microsoft 365 Copilot, Copilot Studio and Foundry. Here I see them from the inside.

**Thesis: tools over model size.** Local 20B to 30B models score below frontier cloud models on benchmarks. With retrieval, web search and an agent around them, a mid-size model covers most daily work. I test this on my own questions in [compare/](compare/).

## Architecture

```
  iPhone ──(Tailscale Serve, HTTPS, tailnet only)──┐
                                                    ├──> Odysseus workspace (auth + 2FA, single admin)
  Browser ──(Cloudflare Tunnel + Access policy)────┘            │
                                                                ▼
                                              Ollama on 127.0.0.1 (never exposed)
                                                                │
                                              RTX 5090 Laptop GPU, 24 GB VRAM
                                    qwen3.8:27b · qwen3.6:27b · gemma4:26b · gpt-oss:20b
```

No router port is open. Details: [docs/architecture.md](docs/architecture.md), [docs/remote-access.md](docs/remote-access.md).

## Hardware

Lenovo Legion Pro 7i Gen 10: Intel Core Ultra 9 275HX (24 cores), 64 GB RAM, NVIDIA RTX 5090 Laptop GPU with 24 GB VRAM (about 21 GB usable), Windows 11 with device encryption.

An 8192 x 8192 matrix multiply takes 2.57 s on CPU and 0.047 s on GPU, about 55x faster ([scripts/gpu_matmul_benchmark.py](scripts/gpu_matmul_benchmark.py)).

## Model lineup (all 100% on GPU)

| Model | Role | Size and speed (measured) |
|---|---|---|
| qwen3.8:27b | All-round, reasoning | 17 GB, 24.3 tokens/s |
| qwen3.6:27b | Coding and agent tasks (PowerShell, scripts) | Dense 27B |
| gemma4:26b | Long documents, summaries | Mixture of experts, about 4B active per token, fast |
| gpt-oss:20b | Fast answers | 13 GB, 104.6 tokens/s |

Skipped: qwen3.6:35b (23 GB) exceeds usable VRAM and would spill into system RAM. See [docs/model-lineup.md](docs/model-lineup.md).

## Stack

| Layer | Choice | Hardening |
|---|---|---|
| Model server | Ollama, bound to 127.0.0.1 | 32K context (default 4K), flash attention, q8_0 KV cache (half the memory of f16), 30 min keep-alive, cloud off ([docs/ollama-tuning.md](docs/ollama-tuning.md)) |
| Workspace | Odysseus (open source, AGPL-3.0): chat, Compare, memory, RAG, deep research, agent, skills, scheduled tasks | 2FA, single admin, sign-up off. Agent shell, file and system tools locked until reviewed. Email and calendar tasks paused |
| Remote access | Tailscale Serve (phone), Cloudflare Tunnel + Cloudflare Access (browser) | No open ports, Funnel never used, Access policy live before the tunnel |
| Operations | Windows scheduled task at logon, laptop awake on AC | `stop-llm.ps1` frees the GPU on demand |

## Status

| Phase | Content | State |
|---|---|---|
| 0 | Prerequisites (drivers, CUDA, encryption) | Done |
| 1 | Ollama installed, tuned and verified | Done |
| 2 | Odysseus installed and hardened | Done |
| 3 | Secure remote access from phone and browser | Done |
| 4 | Four models installed, Compare used to pick a daily driver per task | Done |
| 5 | Documents and RAG | Next |
| 6 | Deep research and web search | Planned |
| 7 | Agent with reviewed tasks | Planned |
| 8 | Personal Gmail triage (drafts only), notes, calendar, reminders | Planned |
| 9 | Scheduled backups | Planned |

Progress log: [CHANGELOG.md](CHANGELOG.md).

## Security

Agent tools that can act on the machine stay locked until reviewed, because retrieved documents and web pages can carry prompt injection. Full threat model: [docs/threat-model.md](docs/threat-model.md).

## Lessons learned

| Lesson | Detail |
|---|---|
| GPU contention | A running game cut speed from 104.6 to 12.15 tokens/s, about 88% lost |
| Default context is too small for agents | 4K tokens fills after a few tool calls; 32K with a q8_0 KV cache fits in VRAM |
| VRAM is the budget | Weights plus KV cache must fit in about 21 GB, or the model spills to RAM and slows down sharply |

More, including quantization limits and Windows setup issues: [docs/lessons-learned.md](docs/lessons-learned.md).

## Learning track: an LLM from scratch

I am working through Sebastian Raschka's *Build a Large Language Model (From Scratch)*, from tokenization and attention to pretraining and fine-tuning. Capstone: a LoRA fine-tune on public PowerShell and Microsoft 365 data, served in Ollama and measured against the base model. Progress: [learning/llm-from-scratch/](learning/llm-from-scratch/).

## How it connects to my work

| Here | At work (Microsoft 365, Copilot, Copilot Studio, Foundry) |
|---|---|
| Context budget and KV cache | Why grounding is selective and long documents get truncated |
| RAG on my own documents | How Copilot and agents retrieve, and why source permissions matter |
| Prompt injection through retrieved content | Locked agent tools, autonomy levels, injection cases in evaluation sets |
| Tokens per second and VRAM | What capacity and Copilot Credits pay for |
| Identity-based remote access, no open ports | Zero Trust and Conditional Access |
| Comparing models on my own questions | Choosing between Copilot Studio and Foundry from tests on real tasks |

Part of [the portfolio](../README.md).

## Rules I follow

No secrets in chats or repositories. No employer or client data. Verify versions before claiming. Measure before claiming an improvement.

## License

Scripts and documentation: MIT, see [LICENSE](../LICENSE). Third-party software keeps its own licence (Odysseus is AGPL-3.0).
