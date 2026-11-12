"""Primary O(n*m) prefix-sum oracle for the bounded Library Checker task."""

from __future__ import annotations

from collections.abc import Sequence

MOD = 998_244_353
MAX_N = 64
MAX_M = 64
MAX_INPUT_LENGTH = 2 + 2 * MAX_N
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_length: int | None):
    if (not isinstance(values, (list, tuple)) or len(values) < 4 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return None
    n, m = values[0], values[1]
    if not 1 <= n <= MAX_N or not 1 <= m <= MAX_M or actual_length != 2 + 2 * n:
        return None
    lower = values[2:2 + n]
    upper = values[2 + n:2 + 2 * n]
    if any(not 0 <= a < b <= m for a, b in zip(lower, upper)):
        return None
    return n, m, lower, upper


def expected_result(values: Sequence[int] | None, input_length: int | None = None) -> int:
    parsed = _parse(values, input_length)
    if parsed is None:
        return INVALID_RESULT
    n, m, lower, upper = parsed

    previous = [0] * m
    for value in range(lower[0], upper[0]):
        previous[value] = 1
    for position in range(1, n):
        current = [0] * m
        prefix = 0
        for value in range(m):
            prefix += previous[value]
            if prefix >= MOD:
                prefix -= MOD
            if lower[position] <= value < upper[position]:
                current[value] = prefix
        previous = current
    return sum(previous) % MOD
