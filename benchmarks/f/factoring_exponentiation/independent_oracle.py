"""Independent repeated-squaring oracle for power-of-two modular exponentiation."""

from __future__ import annotations

from collections.abc import Sequence

MAX_VALID_INPUT_LENGTH = 4
MAX_PARSEABLE_INPUT_LENGTH = 5
MAX_EXPONENT = (1 << 32) - 1
INVALID_RESULT = -1


def expected_result(
    values: Sequence[int] | None,
    *,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> int:
    if (
        type(input_is_null) is not bool
        or input_is_null
        or not isinstance(values, (list, tuple))
        or (input_length is not None and (type(input_length) is not int or input_length != len(values)))
        or not 0 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or len(values) != MAX_VALID_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value <= (1 << 63) - 1 for value in values)
    ):
        return INVALID_RESULT
    remainder, base, exponent, d = values
    if not 3 <= d <= 32 or remainder < 0 or base < 1 or not 0 <= exponent <= MAX_EXPONENT:
        return INVALID_RESULT
    modulus = 1 << d
    if remainder >= modulus or base >= modulus or base % 2 == 0:
        return INVALID_RESULT
    return (remainder * pow(base, exponent, modulus)) % modulus
