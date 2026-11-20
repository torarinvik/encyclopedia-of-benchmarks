"""Backward homogeneous-pair reference, evaluated separately for each prefix."""

from __future__ import annotations

import struct
from typing import Sequence

ALGORITHM = "continued_fraction_forward_series_recurrence"
MODULUS = 998244353
MIN_COEFFICIENTS = 2
MAX_COEFFICIENTS = 9
MAX_VALID_INPUT_LENGTH = 10
MAX_PARSEABLE_INPUT_LENGTH = 11
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
            or not MIN_COEFFICIENTS + 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    count = values[0]
    if not MIN_COEFFICIENTS <= count <= MAX_COEFFICIENTS or len(values) != count + 1:
        return None
    coefficients = list(values[1:])
    if any(not 0 <= value < MODULUS for value in coefficients):
        return None
    return coefficients


def _prefix_convergent(coefficients: Sequence[int], end: int) -> int | None:
    """Evaluate a0/(1-a1/(1-...)) using numerator/denominator pairs."""
    if end == 1:
        return coefficients[0]
    tail_numerator = coefficients[end - 1]
    tail_denominator = 1
    for index in range(end - 2, 0, -1):
        tail_numerator, tail_denominator = (
            coefficients[index] * tail_denominator % MODULUS,
            (tail_denominator - tail_numerator) % MODULUS,
        )
    numerator = coefficients[0] * tail_denominator % MODULUS
    denominator = (tail_denominator - tail_numerator) % MODULUS
    if denominator == 0:
        return None
    return numerator * pow(denominator, MODULUS - 2, MODULUS) % MODULUS


def backward_prefix_values(coefficients: Sequence[int]) -> list[int] | None:
    values: list[int] = []
    for end in range(1, len(coefficients) + 1):
        value = _prefix_convergent(coefficients, end)
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
    prefix_values = backward_prefix_values(coefficients)
    if prefix_values is None:
        return INVALID_RESULT, b""
    required = 8 * (len(coefficients) + 1)
    if (type(output_is_null) is not bool or output_is_null
            or type(capacity) is not int or capacity < required):
        return OUTPUT_ERROR_RESULT, b""
    words = [len(coefficients), *prefix_values]
    return required, struct.pack("<" + "q" * len(words), *words)
