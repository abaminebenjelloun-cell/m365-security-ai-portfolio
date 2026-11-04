# Model lineup

## Criteria

1. Fits **100% in VRAM** with a 32K context and a q8_0 KV cache (about 21 GB usable).
2. One clear job per model, so I can pick the right one per task in Compare.
3. Open weights, installed from the Ollama library.

## Lineup

| Model | Job | Size | Speed (measured) | Notes |
|---|---|---|---|---|
| qwen3.8:27b | All-round, reasoning | 17 GB | 24.3 tokens/s | Daily driver for analysis |
| qwen3.6:27b | Coding, agent tasks, PowerShell | Dense 27B | To measure | Dense models degrade less on code than heavy quantization |
| gemma4:26b | Long documents, summaries | Mixture of experts | To measure | About 4B parameters active per token, so fast for its size |
| gpt-oss:20b | Fast answers | 13 GB | 104.6 tokens/s | First choice for quick questions |
| ~~qwen3.6:35b~~ | | 23 GB | | Excluded: exceeds usable VRAM, would spill into RAM |

Speeds measured with [../scripts/measure_tokens_per_second.py](../scripts/measure_tokens_per_second.py), nothing else on the GPU. With a game running, gpt-oss:20b dropped from 104.6 to 12.15 tokens/s.

## Dense vs mixture of experts

A dense model uses all its parameters for every token. A mixture of experts model routes each token through a few experts, so only a fraction of the parameters is active. It runs faster for the same total size, but all weights must still fit in memory.
