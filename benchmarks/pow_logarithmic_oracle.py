"""Independent oracle for the bounded logarithmic integer-power benchmark."""

from __future__ import annotations

from collections.abc import Sequence

MIN_BASE, MAX_BASE = -10, 10
MIN_EXPONENT, MAX_EXPONENT = 0, 15
MAX_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
INVALID_RESULT = -(1 << 63)
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1


def expected_result(values: Sequence[int]) -> int:
    if (
        not isinstance(values, (list, tuple))
        or len(values) > MAX_PARSEABLE_INPUT_LENGTH
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
        or len(values) != MAX_INPUT_LENGTH
    ):
        return INVALID_RESULT
    base, exponent = values
    if not MIN_BASE <= base <= MAX_BASE or not MIN_EXPONENT <= exponent <= MAX_EXPONENT:
        return INVALID_RESULT
    return pow(base, exponent)
