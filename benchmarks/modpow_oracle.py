"""Independent oracle for bounded modular exponentiation."""

from __future__ import annotations

from collections.abc import Sequence

MAX_COMPONENT = 89_000_000
MAX_EXPONENT = 64
MAX_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 4
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
    base, exponent, modulus = values
    if (
        not 0 <= base <= MAX_COMPONENT
        or not 0 <= exponent <= MAX_EXPONENT
        or not 1 <= modulus <= MAX_COMPONENT
        or (base == 0 and exponent == 0)
    ):
        return INVALID_RESULT
    return pow(base, exponent, modulus)
