"""Two-dimensional prefix-polynomial-hash reference implementation."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_HEIGHT = 32
MAX_WIDTH = 32
MAX_QUERIES = 128
MAX_VALID_INPUT_LENGTH = 3 + MAX_HEIGHT * MAX_WIDTH + 4 * MAX_QUERIES
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * MAX_QUERIES
WORKSPACE_BYTES = 16_384
MODULUS = 1_000_000_007
ROW_BASE = 31
COLUMN_BASE = 37
INVALID_RESULT = -1
OUTPUT_ERROR_RESULT = -2


def _parse(values: Sequence[int] | None, input_is_null: bool,
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
    height, width, query_count = values[:3]
    if not 1 <= height <= MAX_HEIGHT or not 1 <= width <= MAX_WIDTH:
        return None
    if not 1 <= query_count <= MAX_QUERIES:
        return None
    if len(values) != 3 + height * width + 4 * query_count:
        return None
    cells = values[3:3 + height * width]
    if any(not 0 <= value <= 255 for value in cells):
        return None
    queries = []
    offset = 3 + height * width
    for index in range(query_count):
        r0, c0, r1, c1 = values[offset + 4 * index:offset + 4 * index + 4]
        if not (0 <= r0 <= r1 <= height and 0 <= c0 <= c1 <= width):
            return None
        queries.append((r0, c0, r1, c1))
    grid = tuple(tuple(cells[r * width:(r + 1) * width]) for r in range(height))
    return height, width, grid, tuple(queries)


def expected_output(values: Sequence[int] | None, *, capacity: int,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    if (type(output_is_null) is not bool or type(capacity) is not int
            or output_is_null or capacity < 0):
        return OUTPUT_ERROR_RESULT, b""
    height, width, grid, queries = parsed
    required = 8 * len(queries)
    if capacity < required:
        return OUTPUT_ERROR_RESULT, b""

    row_power = [1] * (height + 1)
    col_power = [1] * (width + 1)
    for i in range(1, height + 1):
        row_power[i] = row_power[i - 1] * ROW_BASE % MODULUS
    for j in range(1, width + 1):
        col_power[j] = col_power[j - 1] * COLUMN_BASE % MODULUS
    prefix = [[0] * (width + 1) for _ in range(height + 1)]
    for r in range(1, height + 1):
        row_hash = 0
        for c in range(1, width + 1):
            row_hash = (row_hash * COLUMN_BASE + grid[r - 1][c - 1]) % MODULUS
            prefix[r][c] = (prefix[r - 1][c] * ROW_BASE + row_hash) % MODULUS

    output = bytearray()
    for r0, c0, r1, c1 in queries:
        h, w = r1 - r0, c1 - c0
        value = prefix[r1][c1]
        value -= prefix[r0][c1] * row_power[h] % MODULUS
        value -= prefix[r1][c0] * col_power[w] % MODULUS
        value += prefix[r0][c0] * row_power[h] % MODULUS * col_power[w] % MODULUS
        value %= MODULUS
        output.extend(struct.pack("<q", value))
    return required, bytes(output)
