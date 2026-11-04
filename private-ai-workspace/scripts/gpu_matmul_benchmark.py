#!/usr/bin/env python3
"""Compare CPU and GPU speed on an 8192 x 8192 matrix multiply with PyTorch.

Also a quick check that PyTorch was installed with CUDA support (lesson 5: a plain
pip install on Windows gives a CPU-only build).

Measured on my laptop: CPU 2.57 s, GPU 0.047 s, about 55x faster.
"""

import time

import torch

N = 8192


def timed(device: str) -> float:
    a = torch.randn(N, N, device=device)
    b = torch.randn(N, N, device=device)
    if device == "cuda":
        torch.matmul(a, b)          # warm-up
        torch.cuda.synchronize()
    start = time.perf_counter()
    torch.matmul(a, b)
    if device == "cuda":
        torch.cuda.synchronize()    # wait for the GPU to finish before stopping the clock
    return time.perf_counter() - start


def main() -> None:
    print(f"PyTorch {torch.__version__}, CUDA available: {torch.cuda.is_available()}")
    cpu = timed("cpu")
    print(f"CPU: {cpu:.3f} s")
    if torch.cuda.is_available():
        print(f"GPU: {torch.cuda.get_device_name(0)}")
        gpu = timed("cuda")
        print(f"GPU: {gpu:.3f} s  ({cpu / gpu:.0f}x faster)")
    else:
        print("No CUDA device: install the CUDA build of PyTorch.")


if __name__ == "__main__":
    main()
