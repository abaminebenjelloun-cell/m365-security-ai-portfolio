# Changelog

Newest first: what changed and what was measured.

## November 2026

- Repository created: architecture, Ollama tuning, remote access, threat model, model lineup, lessons learned, scripts.
- Phase 4 done: four models running fully on GPU; Compare used to pick a daily driver per task. Measured: gpt-oss:20b 104.6 tokens/s, qwen3.8:27b 24.3 tokens/s.
- Phase 3 done: phone access through Tailscale Serve, browser access through Cloudflare Tunnel behind Cloudflare Access.
- Phase 2 done: Odysseus installed and hardened (2FA, single admin, sign-up off, agent tools locked).
- Phase 1 done: Ollama tuned (32K context, flash attention, q8_0 KV cache, 30 min keep-alive, cloud off) and verified at 100% GPU.
- Phase 0 done: drivers, CUDA, device encryption. GPU 55x faster than CPU on an 8192 x 8192 matrix multiply.
