"""Stern-Brocot bisection reference for exact question-mark values."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_DENOMINATOR = 1_000_000
MAX_CF_SUM = 60
MAX_VALID_INPUT_LENGTH = 2
MAX_PARSEABLE_INPUT_LENGTH = 3
MAX_OUTPUT_BYTES = 16
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2
WORKSPACE_BYTES = 128


def _read(values: Sequence[int] | None, input_is_null: bool,
          input_length: int | None) -> tuple[int, int] | None:
    if (input_is_null or not isinstance(values, (tuple, list))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if len(values) != MAX_VALID_INPUT_LENGTH:
        return None
    numerator, denominator = values
    if (numerator < 0 or denominator < 1 or denominator > MAX_DENOMINATOR
            or numerator > denominator):
        return None
    return numerator, denominator


def _stern_brocot_value(numerator: int, denominator: int) -> tuple[int, int] | None:
    if numerator == 0:
        return 0, 0
    if numerator == denominator:
        return 1, 0

    low_n, low_d = 0, 1
    high_n, high_d = 1, 1
    low_value, high_value = 0, 1
    depth = 0
    while depth <= MAX_CF_SUM - 2:
        middle_n = low_n + high_n
        middle_d = low_d + high_d
        comparison_left = numerator * middle_d
        comparison_right = denominator * middle_n
        if comparison_left == comparison_right:
            return low_value + high_value, depth + 1
        if comparison_left < comparison_right:
            low_value, high_value = 2 * low_value, low_value + high_value
            high_n, high_d = middle_n, middle_d
        else:
            low_value, high_value = low_value + high_value, 2 * high_value
            low_n, low_d = middle_n, middle_d
        depth += 1
    return None


def expected_output(values: Sequence[int] | None,
                    capacity: int = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False,
                    input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    pair = _read(values, input_is_null, input_length)
    if pair is None:
        return INVALID_RESULT, b""
    value = _stern_brocot_value(*pair)
    if value is None:
        return INVALID_RESULT, b""
    if (type(output_is_null) is not bool or output_is_null
            or type(capacity) is not int or capacity < MAX_OUTPUT_BYTES):
        return OUTPUT_ERROR_RESULT, b""
    return MAX_OUTPUT_BYTES, struct.pack("<qq", *value)
