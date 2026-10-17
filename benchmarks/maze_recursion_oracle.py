"""Oracle for the bounded pinned Java recursive maze solver."""

from __future__ import annotations

from collections.abc import Sequence
import struct

ROWS = 8
COLUMNS = 7
CELL_COUNT = ROWS * COLUMNS
INPUT_LENGTH = 1 + CELL_COUNT
OUTPUT_WORDS = 1 + CELL_COUNT
OUTPUT_BYTES = 4 * OUTPUT_WORDS
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1
OUTPUT_ERROR = -2
START = (1, 1)
TARGET = (6, 5)
STRATEGIES = {
    0: ((1, 0), (0, 1), (-1, 0), (0, -1)),
    1: ((-1, 0), (0, 1), (1, 0), (0, -1)),
}


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the found flag and mutated 8x7 grid, or an ABI error."""
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
    if len(values) != INPUT_LENGTH:
        return INVALID_RESULT, b""
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT, b""

    strategy = values[0]
    if strategy not in STRATEGIES:
        return INVALID_RESULT, b""
    cells = list(values[1:])
    if any(cell not in (0, 1) for cell in cells):
        return INVALID_RESULT, b""
    for row in range(ROWS):
        for column in range(COLUMNS):
            if row in (0, ROWS - 1) or column in (0, COLUMNS - 1):
                if cells[row * COLUMNS + column] != 1:
                    return INVALID_RESULT, b""
    if cells[START[0] * COLUMNS + START[1]] != 0:
        return INVALID_RESULT, b""
    if cells[TARGET[0] * COLUMNS + TARGET[1]] != 0:
        return INVALID_RESULT, b""

    grid = [cells[row * COLUMNS : (row + 1) * COLUMNS] for row in range(ROWS)]

    def set_way(row: int, column: int) -> bool:
        if grid[TARGET[0]][TARGET[1]] == 2:
            return True
        if grid[row][column] == 0:
            grid[row][column] = 2
            for delta_row, delta_column in STRATEGIES[strategy]:
                if set_way(row + delta_row, column + delta_column):
                    return True
            grid[row][column] = 3
        return False

    found = set_way(*START)
    mutated_cells = [cell for row in grid for cell in row]
    output = struct.pack("<57i", int(found), *mutated_cells)
    if len(output) != OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < OUTPUT_BYTES
    ):
        return OUTPUT_ERROR, b""
    return len(output), output
