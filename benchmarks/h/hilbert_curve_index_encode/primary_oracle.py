"""Iterative bitwise Hilbert coordinate-to-index reference."""

from __future__ import annotations

import struct
from typing import Sequence

ALGORITHM = "hilbert_curve_index_encode"
MIN_ORDER = 1
MAX_ORDER = 8
MAX_VALID_INPUT_LENGTH = 3
MAX_PARSEABLE_INPUT_LENGTH = 4
MAX_OUTPUT_BYTES = 8
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2
WORKSPACE_BYTES = 0


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, int] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or (input_length is not None
                and (type(input_length) is not int or input_length != len(values)))
            or len(values) != MAX_VALID_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    order, x, y = values
    if not MIN_ORDER <= order <= MAX_ORDER:
        return None
    side = 1 << order
    if not 0 <= x < side or not 0 <= y < side:
        return None
    return order, x, y


def hilbert_index(order: int, x: int, y: int) -> int:
    """Apply the iterative quadrant/orientation transform from high bits down."""
    current_x = x
    current_y = y
    distance = 0
    for bit_index in range(order - 1, -1, -1):
        bit = 1 << bit_index
        x_bit = int((current_x & bit) != 0)
        y_bit = int((current_y & bit) != 0)
        distance += bit * bit * ((3 * x_bit) ^ y_bit)

        mask = bit - 1
        low_x = current_x & mask
        low_y = current_y & mask
        if y_bit == 0:
            if x_bit == 1:
                low_x = mask - low_x
                low_y = mask - low_y
            current_x, current_y = low_y, low_x
        else:
            current_x, current_y = low_x, low_y
    return distance


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
    result = hilbert_index(*parsed)
    return MAX_OUTPUT_BYTES, struct.pack("<q", result)
