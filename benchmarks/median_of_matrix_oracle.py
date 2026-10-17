"""Oracle for the pinned Java flattened-matrix lower median operation."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_ROWS = 16
MAX_CELLS = 128
MAX_INPUT_LENGTH = 1 + MAX_ROWS + MAX_CELLS
OUTPUT_BYTES = 4
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the flattened lower median or the adapter's ABI status."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if not 1 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""

    row_count = values[0]
    if not 0 <= row_count <= MAX_ROWS:
        return INVALID_RESULT, b""
    position = 1
    flattened: list[int] = []
    for _ in range(row_count):
        if position >= len(values):
            return INVALID_RESULT, b""
        row_length = values[position]
        position += 1
        if row_length == -1:
            continue
        if not 0 <= row_length <= MAX_CELLS:
            return INVALID_RESULT, b""
        if len(flattened) + row_length > MAX_CELLS:
            return INVALID_RESULT, b""
        if row_length > len(values) - position:
            return INVALID_RESULT, b""
        row = values[position : position + row_length]
        if any(not I32_MIN <= value <= I32_MAX for value in row):
            return INVALID_RESULT, b""
        flattened.extend(row)
        position += row_length
    if position != len(values) or not flattened:
        return INVALID_RESULT, b""

    flattened.sort()
    output = struct.pack("<i", flattened[(len(flattened) - 1) // 2])
    if output_is_null or (
        output_capacity is not None and output_capacity < OUTPUT_BYTES
    ):
        return OUTPUT_ERROR, b""
    return OUTPUT_BYTES, output
