"""Right-to-left homogeneous-pair evaluation of each finite fraction prefix."""

from __future__ import annotations

import struct
from typing import Sequence

ALGORITHM = "steed_continued_fraction_convergents"
MODULUS = 998244353
MIN_LEVELS = 1
MAX_LEVELS = 8
MIN_VALID_INPUT_LENGTH = 4
MAX_VALID_INPUT_LENGTH = 18
MAX_PARSEABLE_INPUT_LENGTH = 19
MAX_OUTPUT_BYTES = 80
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2
WORKSPACE_BYTES = 0


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> list[int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or not MIN_VALID_INPUT_LENGTH <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    levels = values[0]
    if not MIN_LEVELS <= levels <= MAX_LEVELS or len(values) != 2 + 2 * levels:
        return None
    coefficients = list(values[1:])
    if any(not 0 <= value < MODULUS for value in coefficients) or coefficients[1] == 0:
        return None
    return coefficients


def _inverse(value: int) -> int:
    return pow(value, MODULUS - 2, MODULUS)


def _backward_prefix(coefficients: Sequence[int], end: int) -> int | None:
    """Return C_end by reducing the suffix b_end + a_(end-1)/... from the right."""
    tail_numerator = coefficients[2 * end - 1]
    tail_denominator = 1
    for level in range(end - 1, 0, -1):
        b_value = coefficients[2 * level - 1]
        next_a = coefficients[2 * level + 2]
        tail_numerator, tail_denominator = (
            (b_value * tail_numerator + next_a * tail_denominator) % MODULUS,
            tail_numerator,
        )
    if tail_numerator == 0:
        return None
    numerator = (coefficients[0] * tail_numerator
                 + coefficients[2] * tail_denominator) % MODULUS
    return numerator * _inverse(tail_numerator) % MODULUS


def backward_convergents(coefficients: Sequence[int]) -> list[int] | None:
    levels = (len(coefficients) - 1) // 2
    values = [coefficients[0]]
    for end in range(1, levels + 1):
        value = _backward_prefix(coefficients, end)
        if value is None:
            return None
        values.append(value)
    return values


def expected_output(values: Sequence[int] | None,
                    capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    coefficients = _parse(values, input_is_null, input_length)
    if coefficients is None:
        return INVALID_RESULT, b""
    convergents = backward_convergents(coefficients)
    if convergents is None:
        return INVALID_RESULT, b""
    levels = (len(coefficients) - 1) // 2
    required = 8 * (levels + 2)
    if (type(output_is_null) is not bool or output_is_null
            or type(capacity) is not int or capacity < required):
        return OUTPUT_ERROR_RESULT, b""
    words = [levels + 1, *convergents]
    return required, struct.pack("<" + "q" * len(words), *words)
