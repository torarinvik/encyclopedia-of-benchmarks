"""Primary exact-DP oracle for the chapter's universal doubling sequence."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 12
MAX_WEIGHT = 32
MAX_INPUT = 25
MAX_OUTPUT = 104


def _pack(words: list[int]) -> bytes:
    return b"".join(struct.pack("<q", word) for word in words)


def _knapsack_dp(processing: list[int], weights: list[int], bound: int) -> int:
    best: list[int | None] = [None] * (bound + 1)
    masks = [0] * (bound + 1)
    best[0] = 0
    for job, (p, w) in enumerate(zip(processing, weights, strict=True)):
        for used in range(bound, w - 1, -1):
            prior = best[used - w]
            if prior is None:
                continue
            candidate = prior + p
            candidate_mask = masks[used - w] | (1 << job)
            if (best[used] is None or candidate > best[used]
                    or candidate == best[used] and candidate_mask < masks[used]):
                best[used] = candidate
                masks[used] = candidate_mask
    chosen_weight = min(
        (used for used, p in enumerate(best) if p is not None),
        key=lambda used: (-best[used], masks[used]),  # type: ignore[operator]
    )
    return masks[chosen_weight]


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or not isinstance(values, (tuple, list))
            or len(values) < 3 or len(values) > MAX_INPUT
            or input_length is not None and
                (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 2 * n:
        return -1, b""
    processing = list(values[1::2])
    weights = list(values[2::2])
    if (any(not 1 <= p <= 255 for p in processing)
            or any(not 1 <= w <= MAX_WEIGHT for w in weights)):
        return -1, b""
    total_weight = sum(weights)
    if total_weight > MAX_WEIGHT or total_weight & (total_weight - 1):
        return -1, b""

    level_sets: list[int] = []
    bound = 1
    while bound <= total_weight:
        level_sets.append(_knapsack_dp(processing, weights, bound))
        bound *= 2
    rank = [-1] * n
    for job in range(n):
        for level, mask in enumerate(level_sets):
            if mask >> job & 1:
                rank[job] = level
                break
        if rank[job] < 0:
            return -1, b""
    permutation = [job for level in range(len(level_sets) - 1, -1, -1)
                   for job in range(n) if rank[job] == level]
    payload = _pack([n, *permutation])
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or output_capacity is not None and output_capacity < len(payload):
        return -2, b""
    return len(payload), payload
