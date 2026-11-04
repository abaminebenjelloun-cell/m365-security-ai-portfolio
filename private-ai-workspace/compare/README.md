# Comparing models on my own questions

Benchmarks measure general ability. I want to know how each model handles my questions, so I run the same prompt on several models side by side in the workspace's Compare view.

## Method

1. Fixed questions from real use, by category: reasoning, coding (PowerShell), long document summary, quick facts, French.
2. Same prompt and context length, nothing else running on the GPU.
3. Score each answer 0 to 2 on correctness and usefulness; note the speed.
4. Pick a daily driver per category. Re-run when I install a new model or quantization.

## Question set

[questions.md](questions.md). No work or client content.

## Results

| Date | Category | qwen3.8:27b | qwen3.6:27b | gemma4:26b | gpt-oss:20b | Daily driver |
|---|---|---|---|---|---|---|
| | Reasoning | | | | | |
| | Coding | | | | | |
| | Long document | | | | | |
| | Quick facts | | | | | |
| | French | | | | | |

Filled only from real runs.
