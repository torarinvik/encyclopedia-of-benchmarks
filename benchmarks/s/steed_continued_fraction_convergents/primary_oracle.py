"""Steed forward recurrence reference over the bounded finite field."""

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


def _coefficients(values: Sequence[int] | None, input_is_null: bool,
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
    if any(not 0 <= value < MODULUS for value in coefficients):
        return None
    if coefficients[1] == 0:
        return None
    return coefficients


def _inverse(value: int) -> int:
    return pow(value, MODULUS - 2, MODULUS)


def _steed_divisors_are_nonzero(coefficients: Sequence[int]) -> bool:
    levels = (len(coefficients) - 1) // 2
    d_value = _inverse(coefficients[1])
    for level in range(2, levels + 1):
        b_value = coefficients[2 * level - 1]
        a_value = coefficients[2 * level]
        denominator = (d_value * a_value + b_value) % MODULUS
        if denominator == 0:
            return False
        d_value = _inverse(denominator)
    return True


def steed_convergents(coefficients: Sequence[int]) -> list[int] | None:
    if not _steed_divisors_are_nonzero(coefficients):
        return None
    levels = (len(coefficients) - 1) // 2
    current = coefficients[0]
    values = [current]
    d_value = _inverse(coefficients[1])
    delta = coefficients[2] * d_value % MODULUS
    current = (current + delta) % MODULUS
    values.append(current)
    for level in range(2, levels + 1):
        b_value = coefficients[2 * level - 1]
        a_value = coefficients[2 * level]
        denominator = (d_value * a_value + b_value) % MODULUS
        d_value = _inverse(denominator)
        factor = (b_value * d_value + MODULUS - 1) % MODULUS
        delta = factor * delta % MODULUS
        current = (current + delta) % MODULUS
        values.append(current)
    return values


def expected_output(values: Sequence[int] | None,
                    capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    coefficients = _coefficients(values, input_is_null, input_length)
    if coefficients is None:
        return INVALID_RESULT, b""
    convergents = steed_convergents(coefficients)
    if convergents is None:
        return INVALID_RESULT, b""
    levels = (len(coefficients) - 1) // 2
    required = 8 * (levels + 2)
    if (type(output_is_null) is not bool or output_is_null
            or type(capacity) is not int or capacity < required):
        return OUTPUT_ERROR_RESULT, b""
    words = [levels + 1, *convergents]
    return required, struct.pack("<" + "q" * len(words), *words)
