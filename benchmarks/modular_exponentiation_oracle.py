"""Independent oracle for the bounded modular exponentiation benchmark."""

from __future__ import annotations

from collections.abc import Sequence

I32_MIN, I32_MAX = -(1 << 31), (1 << 31) - 1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1
MAX_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 4
INVALID_RESULT = -1


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
        not I32_MIN <= base <= I32_MAX
        or not 0 <= exponent <= I32_MAX
        or not 1 <= modulus <= I32_MAX
    ):
        return INVALID_RESULT
    return pow(base, exponent, modulus)
