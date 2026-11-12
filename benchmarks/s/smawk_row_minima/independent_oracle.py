"""Independent per-row scan oracle for SMAWK's row-minimum output."""

from __future__ import annotations

import struct
from collections.abc import Sequence

try:
    from .primary_oracle import MAX_COLUMNS, MAX_PARSEABLE_LENGTH, MAX_ROWS
except ImportError:  # Direct import from the package directory.
    from primary_oracle import MAX_COLUMNS, MAX_PARSEABLE_LENGTH, MAX_ROWS


def _parse(values: Sequence[int] | None) -> tuple[int, int, tuple[int, ...]] | None:
    if not isinstance(values, (list, tuple)) or not 3 <= len(values) <= MAX_PARSEABLE_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    rows, columns = values[:2]
    if not 1 <= rows <= MAX_ROWS or not 1 <= columns <= MAX_COLUMNS:
        return None
    if len(values) != 2 + rows * columns:
        return None
    return rows, columns, tuple(values[2:])


def _scan_minima(rows: int, columns: int, matrix: Sequence[int]) -> list[int]:
    result: list[int] = []
    for row in range(rows):
        best = 0
        for column in range(1, columns):
            if matrix[row * columns + column] < matrix[row * columns + best]:
                best = column
        result.append(best)
    return result


def is_totally_monotone_for_row_minima(rows: int, columns: int, matrix: Sequence[int]) -> bool:
    """Check the pairwise condition equivalent to monotone leftmost minima in every submatrix."""
    for upper in range(rows):
        for lower in range(upper + 1, rows):
            for left in range(columns):
                for right in range(left + 1, columns):
                    if (matrix[upper * columns + left] > matrix[upper * columns + right]
                            and matrix[lower * columns + left] <= matrix[lower * columns + right]):
                        return False
    return True


def expected_output(
    values: Sequence[int] | None,
    capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if (
        type(output_is_null) is not bool
        or type(input_is_null) is not bool
        or capacity is not None and (type(capacity) is not int or capacity < 0)
        or input_length is not None
        and (type(input_length) is not int or not 0 <= input_length <= MAX_PARSEABLE_LENGTH)
        or input_is_null and values not in (None, [], ())
        or not input_is_null and values is not None and input_length is not None
        and input_length != len(values)
    ):
        return -1, b""
    if input_is_null:
        return -1, b""
    parsed = _parse(values)
    if parsed is None:
        return -1, b""
    rows, columns, matrix = parsed
    payload = struct.pack("<" + "q" * rows, *_scan_minima(rows, columns, matrix))
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
