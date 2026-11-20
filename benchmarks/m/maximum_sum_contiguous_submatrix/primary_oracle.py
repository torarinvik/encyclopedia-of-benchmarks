"""Row-compression and Kadane reference for bounded 2D maximum subarray."""
from __future__ import annotations

from struct import pack

MAX_ROWS = 8
MAX_COLUMNS = 8
MIN_CELL = -1000
MAX_CELL = 1000
MAX_VALID_INPUT_LENGTH = 2 + MAX_ROWS * MAX_COLUMNS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8
WORKSPACE_BYTES = 1024


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


def solve(values, *, input_is_null: bool = False,
          input_length: int | None = None) -> int | None:
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return None
    rows, columns, cells = parsed
    best = MIN_CELL * MAX_ROWS * MAX_COLUMNS - 1
    column_sums = [0] * columns
    for top in range(rows):
        column_sums[:] = [0] * columns
        for bottom in range(top, rows):
            row_offset = bottom * columns
            for column in range(columns):
                column_sums[column] += cells[row_offset + column]
            current = column_sums[0]
            best = max(best, current)
            for column in range(1, columns):
                current = max(column_sums[column], current + column_sums[column])
                best = max(best, current)
    return best


def expected_output(values, *, capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    result = solve(values, input_is_null=input_is_null, input_length=input_length)
    if result is None:
        return -1, b""
    if output_is_null or (capacity is not None and capacity < MAX_OUTPUT_BYTES):
        return -2, b""
    return MAX_OUTPUT_BYTES, pack("<q", result)
