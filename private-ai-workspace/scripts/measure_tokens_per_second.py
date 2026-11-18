#!/usr/bin/env python3
"""Measure generation speed (tokens per second) of local Ollama models.

Uses the Ollama HTTP API on localhost: /api/generate with stream=false returns
eval_count (generated tokens) and eval_duration (nanoseconds). Standard library only.

Close games and other GPU applications first, otherwise the result measures contention.

Usage:
  python measure_tokens_per_second.py gpt-oss:20b qwen3.8:27b --runs 3
"""

from __future__ import annotations

import argparse
import json
import statistics
import urllib.request

URL = "http://127.0.0.1:11434/api/generate"
PROMPT = "Explain in about 200 words how attention works in a transformer."


def generate(model: str, prompt: str) -> dict:
    body = json.dumps({"model": model, "prompt": prompt, "stream": False}).encode()
    request = urllib.request.Request(URL, data=body, headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(request, timeout=600) as response:
        return json.loads(response.read())


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("models", nargs="+")
    parser.add_argument("--runs", type=int, default=3)
    args = parser.parse_args()

    print(f"{'Model':<20} {'tok/s (median)':>15} {'runs':>6}")
    for model in args.models:
        generate(model, "Say OK.")  # warm-up: loads the model into VRAM, not measured
        speeds = []
        for _ in range(args.runs):
            result = generate(model, PROMPT)
            if result.get("eval_duration"):
                speeds.append(result["eval_count"] / (result["eval_duration"] / 1e9))
        median = statistics.median(speeds) if speeds else 0.0
        print(f"{model:<20} {median:>15.1f} {len(speeds):>6}")


if __name__ == "__main__":
    main()
