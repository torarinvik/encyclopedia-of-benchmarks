"""Independent oracle for a bounded TSVC s4115 indexed gather reduction."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 64
MAX_INPUT_LENGTH = 1 + 3 * MAX_N
MAX_VALUE = 1_000_000
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None) -> int:
    """Return sum(A[i] * B[indexes[i]]) in source order, or -1 if invalid."""
    if values is None or not isinstance(values, (list, tuple)):
        return -1
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return -1
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1
    n = values[0]
    if not 1 <= n <= MAX_N or len(values) != 1 + 3 * n:
        return -1
    indexes = values[1 : 1 + n]
    a_values = values[1 + n : 1 + 2 * n]
    b_values = values[1 + 2 * n :]
    if any(not 0 <= index < n for index in indexes):
        return -1
    if any(not 0 <= value <= MAX_VALUE for value in (*a_values, *b_values)):
        return -1
    total = 0
    for i in range(n):
        total += a_values[i] * b_values[indexes[i]]
    return total
