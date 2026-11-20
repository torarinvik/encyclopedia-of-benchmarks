"""Recursive quadrant reference for the bounded Hilbert index operation."""

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


def recursive_index(order: int, x: int, y: int) -> int:
    if order == 0:
        return 0
    half = 1 << (order - 1)
    subcurve_size = 1 << (2 * (order - 1))
    low_mask = half - 1
    if x < half:
        if y < half:
            quadrant = 0
            child_x, child_y = y, x
        else:
            quadrant = 1
            child_x, child_y = x, y - half
    elif y >= half:
        quadrant = 2
        child_x, child_y = x - half, y - half
    else:
        quadrant = 3
        low_x, low_y = x & low_mask, y & low_mask
        child_x, child_y = low_mask - low_y, low_mask - low_x
    return quadrant * subcurve_size + recursive_index(
        order - 1, child_x, child_y)


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
    return MAX_OUTPUT_BYTES, struct.pack("<q", recursive_index(*parsed))
