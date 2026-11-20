"""Direct weighted-cell rectangle reference, independent of prefix extraction."""

from __future__ import annotations

from collections.abc import Sequence
import struct

from .primary_oracle import (
    COLUMN_BASE, INVALID_RESULT, MAX_HEIGHT, MAX_PARSEABLE_INPUT_LENGTH,
    MAX_QUERIES, MAX_WIDTH, MODULUS, OUTPUT_ERROR_RESULT,
)

ROW_BASE = 31


def _decode(values: Sequence[int] | None, input_is_null: bool,
            input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 3 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    h, w, q = values[:3]
    if not 1 <= h <= MAX_HEIGHT or not 1 <= w <= MAX_WIDTH or not 1 <= q <= MAX_QUERIES:
        return None
    cell_end = 3 + h * w
    if len(values) != cell_end + 4 * q:
        return None
    grid = tuple(values[3:cell_end])
    if any(value < 0 or value > 255 for value in grid):
        return None
    queries = []
    for i in range(q):
        r0, c0, r1, c1 = values[cell_end + 4 * i:cell_end + 4 * i + 4]
        if not (0 <= r0 <= r1 <= h and 0 <= c0 <= c1 <= w):
            return None
        queries.append((r0, c0, r1, c1))
    return h, w, grid, tuple(queries)


def expected_output(values: Sequence[int] | None, *, capacity: int,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _decode(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    if (type(output_is_null) is not bool or type(capacity) is not int
            or output_is_null or capacity < 0):
        return OUTPUT_ERROR_RESULT, b""
    height, width, flat_grid, queries = parsed
    required = 8 * len(queries)
    if capacity < required:
        return OUTPUT_ERROR_RESULT, b""
    powers_row = [pow(ROW_BASE, i, MODULUS) for i in range(height)]
    powers_col = [pow(COLUMN_BASE, j, MODULUS) for j in range(width)]
    output = bytearray()
    for r0, c0, r1, c1 in queries:
        value = 0
        for r in range(r0, r1):
            for c in range(c0, c1):
                cell = flat_grid[r * width + c]
                value = (value + cell * powers_row[r1 - 1 - r]
                         * powers_col[c1 - 1 - c]) % MODULUS
        output.extend(struct.pack("<q", value))
    return required, bytes(output)
