# Lessons learned

| # | Lesson | Detail | What I do now |
|---|---|---|---|
| 1 | GPU contention | A running game cut gpt-oss:20b from 104.6 to 12.15 tokens/s (about 88% lost) | Run `stop-llm.ps1` before gaming; close GPU apps before measuring |
| 2 | Default context too small | 4K tokens fills after a few agent tool calls | 32K context with a q8_0 KV cache |
| 3 | VRAM is the budget | Weights plus KV cache must fit, or the model spills to RAM | Check that `ollama ps` shows 100% GPU for every model |
| 4 | Quantization limit | Quality holds to about 3 to 4 bits; coding degrades first | Keep the coding model at higher precision |
| 5 | PyTorch on Windows | A plain `pip install torch` gave a CPU-only build | Install the CUDA wheel from the PyTorch selector, then check `torch.cuda.is_available()` |
| 6 | `.env` and BOM | Notepad saved a byte order mark that broke the `.env` file | Edit config files in VS Code, UTF-8 without BOM |
| 7 | Remote access order | A tunnel live before its access policy is a public endpoint | Create the identity policy first, then the tunnel |
