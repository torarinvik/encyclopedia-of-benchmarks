"""SMAWK row-minimum oracle for bounded totally monotone matrices."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_ROWS = 16
MAX_COLUMNS = 16
MAX_INPUT_LENGTH = 2 + MAX_ROWS * MAX_COLUMNS
MAX_PARSEABLE_LENGTH = MAX_INPUT_LENGTH + 2
MAX_OUTPUT_BYTES = MAX_ROWS * 8
WORKSPACE_BYTES = 4096


def _smawk(matrix: Sequence[int], width: int, rows: Sequence[int],
           columns: Sequence[int], answer: list[int]) -> None:
    if not rows:
        return
    if len(rows) == 1:
        row = rows[0]
        best = columns[0]
        for column in columns[1:]:
            if matrix[row * width + column] < matrix[row * width + best]:
                best = column
        answer[row] = best
        return

    reduced: list[int] = []
    for column in columns:
        while reduced:
            comparison_row = rows[len(reduced) - 1]
            if matrix[comparison_row * width + column] < matrix[comparison_row * width + reduced[-1]]:
                reduced.pop()
            else:
                break
        if len(reduced) < len(rows):
            reduced.append(column)

    odd_rows = rows[1::2]
    _smawk(matrix, width, odd_rows, reduced, answer)
    reduced_position = {column: position for position, column in enumerate(reduced)}
    for row_index in range(0, len(rows), 2):
        start = 0 if row_index == 0 else reduced_position[answer[rows[row_index - 1]]]
        end = len(reduced) - 1
        if row_index + 1 < len(rows):
            end = reduced_position[answer[rows[row_index + 1]]]
        row = rows[row_index]
        best = reduced[start]
        for position in range(start + 1, end + 1):
            column = reduced[position]
            if matrix[row * width + column] < matrix[row * width + best]:
                best = column
        answer[row] = best


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
    minima = [-1] * rows
    _smawk(matrix, columns, list(range(rows)), list(range(columns)), minima)
    payload = struct.pack("<" + "q" * rows, *minima)
    if output_is_null or capacity is not None and capacity < len(payload):
        return -2, b""
    return len(payload), payload
