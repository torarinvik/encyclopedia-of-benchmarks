"""Reference implementation of the batched small-k Josephus recurrence."""

from __future__ import annotations

MAX_N = 1_000_000
MAX_K = 32
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
WORKSPACE_BYTES = 16_384


def josephus_batched_small_k(values: list[int]) -> int:
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return -1
    n, k = values
    if not (1 <= n <= MAX_N and 1 <= k <= MAX_K):
        return -1
    if n == 1:
        return 0
    if k == 1:
        return n - 1

    frames: list[int] = []
    while n > 1:
        frames.append(n)
        n = n - 1 if n < k else n - n // k

    survivor = 0
    while frames:
        m = frames.pop()
        if m < k:
            survivor = (survivor + k) % m
        else:
            survivor -= m % k
            if survivor < 0:
                survivor += m
            else:
                survivor += survivor // (k - 1)
    return survivor
