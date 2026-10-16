"""Independent oracle for Java hexadecimal-to-octal integer conversion."""

from __future__ import annotations

from collections.abc import Sequence

MAX_INPUT_LENGTH = 8
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
I64_MIN, I64_MAX = -(1 << 63), (1 << 63) - 1
I32_MIN, I32_MAX = -(1 << 31), (1 << 31) - 1
I32_MODULUS = 1 << 32
INVALID_RESULT = -(1 << 31) - 1


def _signed_i32(bits: int) -> int:
    bits &= I32_MODULUS - 1
    return bits if bits <= I32_MAX else bits - I32_MODULUS


def expected_result(values: Sequence[int]) -> int:
    """Return the signed Java int produced by the bounded source conversion."""
    if (not isinstance(values, (list, tuple)) or len(values) > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
            or len(values) > MAX_INPUT_LENGTH):
        return INVALID_RESULT

    decimal_bits = 0
    for code in values:
        if 48 <= code <= 57:
            digit = code - 48
        elif 65 <= code <= 70:
            digit = code - 55
        elif 97 <= code <= 102:
            digit = code - 87
        else:
            return INVALID_RESULT
        decimal_bits = (decimal_bits * 16 + digit) & (I32_MODULUS - 1)

    decimal_value = _signed_i32(decimal_bits)
    if decimal_value <= 0:
        return 0

    octal_bits = 0
    place_value = 1
    while decimal_value > 0:
        octal_bits = (octal_bits + (decimal_value % 8) * place_value) & (I32_MODULUS - 1)
        decimal_value //= 8
        place_value = (place_value * 10) & (I32_MODULUS - 1)
    return _signed_i32(octal_bits)
