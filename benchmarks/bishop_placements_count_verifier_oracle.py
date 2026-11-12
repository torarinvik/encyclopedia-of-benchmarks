"""Independent diagonal-mask subset DP for exact bishop placement counts."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 8
MAX_K = 16


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or len(values) != 2:
        return -1
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63) for value in values):
        return -1
    n, k = values
    if not 1 <= n <= MAX_N or not 0 <= k <= MAX_K:
        return -1
    if k > (1 if n == 1 else 2 * n - 2):
        return 0

    diagonal_count = 2 * n - 1
    state_count = 1 << diagonal_count
    ways = [0] * state_count
    ways[0] = 1
    for descending in range(-(n - 1), n):
        following = ways.copy()
        for used_mask, count in enumerate(ways):
            placed = used_mask.bit_count()
            if count == 0 or placed == k:
                continue
            for row in range(n):
                column = row - descending
                if not 0 <= column < n:
                    continue
                ascending = row + column
                bit = 1 << ascending
                if used_mask & bit == 0:
                    following[used_mask | bit] += count
        ways = following
    return sum(count for mask, count in enumerate(ways) if mask.bit_count() == k)
