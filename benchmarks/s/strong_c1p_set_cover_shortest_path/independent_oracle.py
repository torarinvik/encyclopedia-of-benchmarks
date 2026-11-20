"""Independent subset-enumeration oracle for strong-C1P set cover."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_ROWS = 8
MAX_COLUMNS = 10
MAX_PARSEABLE_INPUT_LENGTH = 21


def _parse(values: Sequence[int] | None):
    if (not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    rows, columns = values[:2]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS:
        return None
    if len(values) != 2 + rows + columns:
        return None
    weights = list(values[2:2 + columns])
    masks = list(values[2 + columns:])
    if any(weight < 1 or weight > 20 for weight in weights):
        return None
    allowed = (1 << columns) - 1
    if any(mask < 0 or mask & ~allowed for mask in masks):
        return None
    for mask in masks:
        seen_one = False
        seen_zero_after = False
        for column in range(columns):
            if mask & (1 << column):
                if seen_zero_after:
                    return None
                seen_one = True
            elif seen_one:
                seen_zero_after = True
    return columns, weights, masks


def expected_output(values: Sequence[int] | None, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or capacity is not None and (type(capacity) is not int or capacity < 0)
            or input_length is not None and (type(input_length) is not int
                                             or not 0 <= input_length <= MAX_PARSEABLE_INPUT_LENGTH)
            or input_is_null and values not in (None, [], ())
            or not input_is_null and values is not None and input_length is not None
            and input_length != len(values)):
        return -1, b""
    if input_is_null or values is None:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    columns, weights, masks = parsed
    optimum: int | None = None
    for selected in range(1 << columns):
        if not all(selected & row_mask for row_mask in masks):
            continue
        cost = sum(weights[column] for column in range(columns)
                   if selected & (1 << column))
        if optimum is None or cost < optimum:
            optimum = cost
    payload = struct.pack("<q", -1 if optimum is None else optimum)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
