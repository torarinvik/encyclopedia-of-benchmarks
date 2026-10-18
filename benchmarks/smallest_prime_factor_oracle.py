"""Oracle for the bounded primelib smallest-prime-factor routine."""

from __future__ import annotations

from collections.abc import Sequence

MIN_N = 2
MAX_N = 1_000_005
MAX_INPUT_LENGTH = 2
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None) -> int:
    """Return the smallest prime factor, or -1 for malformed/out-of-range input."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) != 1
        or type(values[0]) is not int
        or not -(1 << 63) <= values[0] < (1 << 63)
    ):
        return INVALID_RESULT
    number = values[0]
    if not MIN_N <= number <= MAX_N:
        return INVALID_RESULT

    factor = 2
    while factor <= number // factor:
        if number % factor == 0:
            return factor
        factor += 1
    return number
