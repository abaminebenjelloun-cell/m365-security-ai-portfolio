# Ollama tuning

Last reviewed November 2026 against the Ollama FAQ (docs.ollama.com/faq).

## Settings

| Variable | Value | Default | Why |
|---|---|---|---|
| `OLLAMA_HOST` | `127.0.0.1:11434` | Same | Set explicitly: the model API is never exposed |
| `OLLAMA_CONTEXT_LENGTH` | `32768` | 4096 | Agents, RAG and long documents need room. 4K fills after a few tool calls |
| `OLLAMA_FLASH_ATTENTION` | `1` | Automatic when supported | Forced on; KV cache quantization requires it |
| `OLLAMA_KV_CACHE_TYPE` | `q8_0` | `f16` | About half the KV cache memory of f16 with very small precision loss, so 32K context fits in VRAM. Applies to all models |
| `OLLAMA_KEEP_ALIVE` | `30m` | 5 minutes | Avoids reloading a 17 GB model between questions |
| `OLLAMA_NO_CLOUD` | `1` | Cloud on | Local-only: no cloud models, no Ollama web search |

I set these as user environment variables ([../scripts/Set-OllamaEnv.ps1](../scripts/Set-OllamaEnv.ps1)), then quit Ollama from the taskbar and restart it.

## Verify

```powershell
ollama ps            # Processor column must show 100% GPU
ollama list          # Installed models and sizes
```

`100% GPU` means the whole model is in VRAM. A split such as `30%/70% CPU/GPU` means it spilled into system memory and will be much slower. Use a smaller model or context.

## VRAM budget

```
usable VRAM (about 21 GB)  >=  model weights  +  KV cache (grows with context length)  +  overhead
```

This is why the 23 GB model is excluded, and why I quantize the KV cache to keep the 32K context.
