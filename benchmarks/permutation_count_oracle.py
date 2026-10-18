"""Oracle for the bounded Julia nPr count variant of permutation."""

from __future__ import annotations

from collections.abc import Sequence

MAX_N = 18
MAX_R = 18
MAX_INPUT_LENGTH = 3
INVALID_RESULT = -1


def factorial_source_semantics(value: int) -> int:
    """Model the pinned helper's product over ``1:value`` (empty if value < 1)."""
    result = 1
    for factor in range(1, value + 1):
        result *= factor
    return result


def expected_result(values: Sequence[int] | None) -> int:
    """Return the source's n! / (n-r)! count, or -1 outside the bounded ABI."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) != 2
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return INVALID_RESULT
    n, r = values
    if not 0 <= n <= MAX_N or not 0 <= r <= MAX_R:
        return INVALID_RESULT

    # For r > n the pinned factorial helper sees a negative argument, whose
    # 1:value loop is empty and therefore returns 1. Keep that source edge case.
    numerator = factorial_source_semantics(n)
    denominator = factorial_source_semantics(n - r)
    return numerator // denominator
