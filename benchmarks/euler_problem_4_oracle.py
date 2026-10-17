"""Independent brute-force oracle for Project Euler problem 4."""

from __future__ import annotations

from collections.abc import Sequence

MAX_DIGITS = 3
MAX_PARSEABLE_INPUT_LENGTH = 2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_result(values: Sequence[int] | None) -> int:
    """Return the largest d-digit-factor palindrome, or -1 for invalid input."""
    if (
        not isinstance(values, (list, tuple))
        or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return -1
    if len(values) != 1 or not 1 <= values[0] <= MAX_DIGITS:
        return -1
    digits = values[0]
    lower = 10 ** (digits - 1)
    upper = 10**digits - 1
    return max(
        product
        for left in range(lower, upper + 1)
        for right in range(lower, upper + 1)
        if (product := left * right) and str(product) == str(product)[::-1]
    )
