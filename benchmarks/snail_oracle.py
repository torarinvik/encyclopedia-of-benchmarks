"""Oracle for the bounded pinned Rust snail traversal."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_ROWS = 16
MAX_COLUMNS = 16
MAX_CELLS = MAX_ROWS * MAX_COLUMNS
MAX_VALID_INPUT_LENGTH = 2 + MAX_CELLS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = MAX_CELLS * 4
I32_MIN = -(1 << 31)
I32_MAX = (1 << 31) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the clockwise inward matrix traversal as little-endian i32 bytes."""
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
    if not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I32_MIN <= value <= I32_MAX for value in values):
        return INVALID_RESULT, b""

    rows, columns = values[:2]
    if not 0 <= rows <= MAX_ROWS or not 0 <= columns <= MAX_COLUMNS:
        return INVALID_RESULT, b""
    if rows == 0 and columns != 0:
        return INVALID_RESULT, b""
    if columns == 1 and rows != 1:
        return INVALID_RESULT, b""
    cell_count = rows * columns
    if len(values) != 2 + cell_count:
        return INVALID_RESULT, b""

    result: list[int] = []
    if cell_count:
        top, bottom = 0, rows - 1
        left, right = 0, columns - 1
        while top <= bottom and left <= right:
            for column in range(left, right + 1):
                result.append(values[2 + top * columns + column])
            top += 1

            for row in range(top, bottom + 1):
                result.append(values[2 + row * columns + right])
            right -= 1

            if top <= bottom and left <= right:
                for column in range(right, left - 1, -1):
                    result.append(values[2 + bottom * columns + column])
                bottom -= 1

            if top <= bottom and left <= right:
                for row in range(bottom, top - 1, -1):
                    result.append(values[2 + row * columns + left])
                left += 1

    encoded = struct.pack("<" + "i" * len(result), *result)
    if len(encoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(encoded)
    ):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
