"""Independent oracle for the bounded TSVC s3111 conditional sum."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 64
MAX_INPUT_LENGTH = 1 + MAX_N
MAX_VALUE = 1_000_000
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None) -> int:
    """Return the sum of strictly positive values, or -1 for invalid input."""
    if values is None or not isinstance(values, (list, tuple)):
        return -1
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return -1
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return -1
    n = values[0]
    if not 0 <= n <= MAX_N or len(values) != 1 + n:
        return -1
    data = values[1:]
    if any(not -MAX_VALUE <= value <= MAX_VALUE for value in data):
        return -1
    return sum(value for value in data if value > 0)
