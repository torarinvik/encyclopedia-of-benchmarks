"""Continued-fraction alternating-sum reference for the question-mark map."""

from __future__ import annotations

import struct
from collections.abc import Sequence

ALGORITHM = "minkowski_question_mark_rational"
MAX_DENOMINATOR = 1_000_000
MAX_CF_SUM = 60
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 16
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2
WORKSPACE_BYTES = 128


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, int] | None:
    if (input_is_null or not isinstance(values, (tuple, list))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if len(values) != 2:
        return None
    numerator, denominator = values
    if (numerator < 0 or denominator < 1 or denominator > MAX_DENOMINATOR
            or numerator > denominator):
        return None

    total = 0
    n, d = numerator, denominator
    while n != 0:
        quotient = d // n
        if quotient > MAX_CF_SUM - total:
            return None
        total += quotient
        d, n = n, d % n
    return numerator, denominator, total


def question_mark_pair(numerator: int, denominator: int,
                       coefficient_sum: int) -> tuple[int, int]:
    if numerator == 0:
        return 0, 0
    total = coefficient_sum
    n, d = numerator, denominator
    prefix = 0
    partial = 0
    index = 1
    while n != 0:
        quotient = d // n
        prefix += quotient
        term = 1 << (total - prefix)
        partial += term if index & 1 else -term
        d, n = n, d % n
        index += 1
    return partial, total - 1


def expected_output(values: Sequence[int] | None,
                    capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    if (type(output_is_null) is not bool or output_is_null
            or type(capacity) is not int or capacity < MAX_OUTPUT_BYTES):
        return OUTPUT_ERROR_RESULT, b""
    numerator, denominator, coefficient_sum = parsed
    value_numerator, exponent = question_mark_pair(
        numerator, denominator, coefficient_sum)
    return MAX_OUTPUT_BYTES, struct.pack("<qq", value_numerator, exponent)
