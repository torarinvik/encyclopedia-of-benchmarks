"""Independent closed-form oracle for Project Euler problem 6."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 100
MAX_PARSEABLE_INPUT_LENGTH = 2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None) -> int:
    """Return square-of-sum minus sum-of-squares, or -1 for invalid input."""
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1
    if len(values) != 1 or not 1 <= values[0] <= MAX_N:
        return -1
    n = values[0]
    return n * (n + 1) * (3 * n * n - n - 2) // 12
