"""Divide-and-conquer optimized partition DP reference."""

from __future__ import annotations

MAX_N = 64
MAX_GROUPS = 8
MAX_VALUE = 1_000
INF = (1 << 62)


def expected_result(values: list[int], *, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    length = len(values) if input_length is None else input_length
    if input_is_null or length != len(values) or length < 3 or length > MAX_N + 2:
        return -1
    n, groups = values[0], values[1]
    if n < 1 or n > MAX_N or groups < 1 or groups > MAX_GROUPS or groups > n:
        return -1
    if length != n + 2:
        return -1
    weights = values[2:]
    if any(weight < 0 or weight > MAX_VALUE for weight in weights):
        return -1

    prefix = [0] * (n + 1)
    for i, weight in enumerate(weights):
        prefix[i + 1] = prefix[i] + weight
    previous = [INF] * (n + 1)
    previous[0] = 0
    for group in range(1, groups + 1):
        current = [INF] * (n + 1)
        stack = [(group, n, group - 1, n - 1)]
        while stack:
            left, right, opt_low, opt_high = stack.pop()
            if left > right:
                continue
            middle = (left + right) // 2
            upper = min(opt_high, middle - 1)
            best = INF
            best_split = opt_low
            for split in range(opt_low, upper + 1):
                if previous[split] == INF:
                    continue
                segment = prefix[middle] - prefix[split]
                candidate = previous[split] + segment * segment
                if candidate < best:
                    best = candidate
                    best_split = split
            current[middle] = best
            if middle < right:
                stack.append((middle + 1, right, best_split, opt_high))
            if left < middle:
                stack.append((left, middle - 1, opt_low, best_split))
        previous = current
    return previous[n]
