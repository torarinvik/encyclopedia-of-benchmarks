"""Reciprocal-quotient Barrett reduction reference."""

from __future__ import annotations

from collections.abc import Sequence

MIN_MODULUS = 2
MAX_MODULUS = 65535
MAX_VALUES = 12
MAX_VALID_INPUT_LENGTH = 14
MAX_PARSEABLE_INPUT_LENGTH = 15
MAX_RESULT = 5_111_730
INVALID_RESULT = -1
RADIX = 1 << 32


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, tuple[int, ...]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    modulus, count = values[0], values[1]
    if not MIN_MODULUS <= modulus <= MAX_MODULUS:
        return None
    if not 0 <= count <= MAX_VALUES or input_length != 2 + count:
        return None
    bound = modulus * modulus
    operands = tuple(values[2:])
    if any(value < 0 or value >= bound for value in operands):
        return None
    return modulus, operands


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    modulus, operands = parsed
    reciprocal = RADIX // modulus
    checksum = 0
    for index, value in enumerate(operands):
        quotient = (value * reciprocal) // RADIX
        remainder = value - quotient * modulus
        if remainder >= modulus:
            remainder -= modulus
        checksum += (index + 1) * (remainder + 1)
    return checksum
