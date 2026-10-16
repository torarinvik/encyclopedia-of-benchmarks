"""Reference contract for bounded identity-preserving graph cloning."""
from __future__ import annotations

MAX_N = 16
MAX_INPUT_LENGTH = 2 + 2 * MAX_N
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
MASK64 = (1 << 64) - 1
INVALID = -1


def expected_result(values: list[int]) -> int:
    if not isinstance(values, list) or len(values) < 4 or len(values) > MAX_INPUT_LENGTH:
        return INVALID
    n, root = values[:2]
    if type(n) is not int or type(root) is not int or not 1 <= n <= MAX_N or not 0 <= root < n or len(values) != 2 + 2*n:
        return INVALID
    labels, masks = values[2:2+n], values[2+n:]
    limit = (1 << n) - 1
    if any(type(x) is not int or not I32_MIN <= x <= I32_MAX for x in labels):
        return INVALID
    if any(type(x) is not int or x < 0 or x > limit for x in masks):
        return INVALID
    for i, row in enumerate(masks):
        for j in range(n):
            if ((row >> j) & 1) != ((masks[j] >> i) & 1):
                return INVALID
    # Match the source's reachable-component behavior; ids are serialization labels only.
    seen = {root}
    stack = [root]
    while stack:
        i = stack.pop()
        for j in range(n):
            if (masks[i] >> j) & 1 and j not in seen:
                seen.add(j)
                stack.append(j)
    h = 14695981039346656037
    def add_word(word: int) -> None:
        nonlocal h
        bits = word & MASK64
        for _ in range(8):
            h ^= bits & 255
            h = (h * 1099511628211) & MASK64
            bits >>= 8
    add_word(len(seen))
    add_word(root)
    for i in range(n):
        if i in seen:
            add_word(labels[i])
            add_word(masks[i])
    return h if h < (1 << 63) else h - (1 << 64)
