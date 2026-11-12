"""Independent O(n*m^2) memoized DFS oracle for bounded sequence counts."""

from __future__ import annotations

from collections.abc import Sequence
from functools import lru_cache

MOD = 998_244_353
MAX_N = 64
MAX_M = 64
MAX_INPUT_LENGTH = 130
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None, input_length: int | None = None) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) < 4 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    size = len(values) if input_length is None else input_length
    if type(size) is not int or size != len(values):
        return INVALID_RESULT
    n, m = values[0], values[1]
    if n < 1 or n > MAX_N or m < 1 or m > MAX_M or size != 2 + 2 * n:
        return INVALID_RESULT
    lower = values[2:2 + n]
    upper = values[2 + n:2 + 2 * n]
    for a, b in zip(lower, upper):
        if a < 0 or a >= b or b > m:
            return INVALID_RESULT

    @lru_cache(maxsize=None)
    def count_from(position: int, previous: int) -> int:
        if position == n:
            return 1
        total = 0
        first = max(previous, lower[position])
        for value in range(first, upper[position]):
            total += count_from(position + 1, value)
            total %= MOD
        return total

    return count_from(0, 0)
