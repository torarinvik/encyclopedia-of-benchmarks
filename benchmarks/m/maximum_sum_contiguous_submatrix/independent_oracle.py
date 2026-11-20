"""Exhaustive rectangle-sum verifier for the bounded 2D profile."""
from __future__ import annotations

from struct import pack, unpack

from .primary_oracle import (
    MAX_COLUMNS, MAX_OUTPUT_BYTES, MAX_PARSEABLE_INPUT_LENGTH, MAX_ROWS,
    MIN_CELL, MAX_CELL,
)


def _parse(values, input_is_null: bool, input_length: int | None):
    if (values is None or input_is_null or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
           for value in values):
        return None
    if input_length is not None and input_length != len(values):
        return None
    rows, columns = values[:2]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS:
        return None
    if len(values) != 2 + rows * columns:
        return None
    cells = values[2:]
    if any(value < MIN_CELL or value > MAX_CELL for value in cells):
        return None
    return rows, columns, cells


def verify_result(values, result: int, payload: bytes, *,
                  output_capacity: int | None = None, output_is_null: bool = False,
                  input_is_null: bool = False, input_length: int | None = None) -> bool:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return result == -1 and payload == b""
    if output_is_null or (output_capacity is not None
                          and output_capacity < MAX_OUTPUT_BYTES):
        return result == -2 and payload == b""
    if result != MAX_OUTPUT_BYTES or len(payload) != MAX_OUTPUT_BYTES:
        return False
    rows, columns, cells = parsed
    returned = unpack("<q", payload)[0]
    maximum = MIN_CELL * MAX_ROWS * MAX_COLUMNS - 1
    for top in range(rows):
        for bottom in range(top, rows):
            for left in range(columns):
                for right in range(left, columns):
                    total = sum(cells[row * columns + column]
                                for row in range(top, bottom + 1)
                                for column in range(left, right + 1))
                    maximum = max(maximum, total)
    return returned == maximum
