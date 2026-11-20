"""Lentz successive-convergent-ratio recurrence over a bounded finite field."""

from __future__ import annotations

import struct
from collections.abc import Sequence

ALGORITHM = "lentz_continued_fraction_convergents"
MODULUS = 998244353
MIN_TERMS = 1
MAX_TERMS = 8
MAX_VALID_INPUT_LENGTH = 2 + 2 * MAX_TERMS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_TERMS + 2)
WORKSPACE_BYTES = 128
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, list[tuple[int, int]]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (tuple, list))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    if input_length is None:
        input_length = len(values)
    if type(input_length) is not int or input_length != len(values):
        return None
    count = values[0]
    if not MIN_TERMS <= count <= MAX_TERMS or input_length != 2 + 2 * count:
        return None
    if any(not 0 <= value < MODULUS for value in values[1:]):
        return None
    initial = values[1]
    if initial == 0:
        return None
    terms = [(values[2 + 2 * index], values[3 + 2 * index])
             for index in range(count)]
    return count, initial, terms


def lentz_trace(initial: int, terms: Sequence[tuple[int, int]]) -> list[int] | None:
    """Apply the exact nonsingular C/D ratio recurrence; no zero shifts are used."""
    value = initial
    c_ratio = initial
    d_ratio = 0
    trace = [value]
    for numerator, denominator in terms:
        d_denominator = (denominator + numerator * d_ratio) % MODULUS
        if d_denominator == 0 or c_ratio == 0:
            return None
        c_value = (denominator + numerator * pow(c_ratio, MODULUS - 2, MODULUS)) % MODULUS
        if c_value == 0:
            return None
        d_ratio = pow(d_denominator, MODULUS - 2, MODULUS)
        value = value * c_value % MODULUS * d_ratio % MODULUS
        c_ratio = c_value
        trace.append(value)
    return trace


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    count, initial, terms = parsed
    trace = lentz_trace(initial, terms)
    if trace is None:
        return INVALID_RESULT, b""
    required = 8 * (count + 2)
    effective_capacity = MAX_OUTPUT_BYTES if capacity is None else capacity
    if (type(output_is_null) is not bool or output_is_null
            or type(effective_capacity) is not int or effective_capacity < 0
            or effective_capacity < required):
        return OUTPUT_ERROR_RESULT, b""
    return required, struct.pack("<" + "q" * (count + 2), count + 1, *trace)
