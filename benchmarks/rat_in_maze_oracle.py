"""Oracle for the bounded Python and Rust rat-in-a-maze variants."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_DIMENSION = 8
MAX_VALID_INPUT_LENGTH = 70
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_WORDS = MAX_DIMENSION * MAX_DIMENSION
MAX_OUTPUT_BYTES = MAX_OUTPUT_WORDS * 8
INVALID_RESULT = -1
OUTPUT_ERROR = -2
NO_PATH_RESULT = -3

PYTHON_VARIANT = 0
RUST_VARIANT = 1


def _invalid() -> tuple[int, bytes]:
    return INVALID_RESULT, b""


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return a source-variant solution matrix or the documented ABI status."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return _invalid()
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return _invalid()
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return _invalid()
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return _invalid()
    if input_length is not None and input_length != len(values):
        return _invalid()
    if (not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return _invalid()

    variant = values[0]
    if variant == PYTHON_VARIANT:
        if len(values) < 7:
            return _invalid()
        size, source_row, source_col, destination_row, destination_col = values[1:6]
        if not 1 <= size <= MAX_DIMENSION or len(values) != 6 + size * size:
            return _invalid()
        rows = cols = size
        start = (source_row, source_col)
        destination = (destination_row, destination_col)
        open_value = 0
        directions = ((1, 0), (0, 1), (-1, 0), (0, -1))
        cells = values[6:]
    elif variant == RUST_VARIANT:
        if len(values) < 6:
            return _invalid()
        rows, cols, source_row, source_col = values[1:5]
        if (not 1 <= rows <= MAX_DIMENSION or not 1 <= cols <= MAX_DIMENSION
                or len(values) != 5 + rows * cols):
            return _invalid()
        start = (source_row, source_col)
        destination = (rows - 1, cols - 1)
        open_value = 1
        directions = ((0, 1), (1, 0), (0, -1), (-1, 0))
        cells = values[5:]
    else:
        return _invalid()

    if not (0 <= start[0] < rows and 0 <= start[1] < cols
            and 0 <= destination[0] < rows and 0 <= destination[1] < cols):
        return _invalid()
    if any(cell not in (0, 1) for cell in cells):
        return _invalid()

    maze = [list(cells[row * cols:(row + 1) * cols]) for row in range(rows)]
    solution = [[False] * cols for _ in range(rows)]

    def search(row: int, col: int) -> bool:
        # Rust's base case precedes validity checks and accepts a blocked goal.
        if variant == RUST_VARIANT and (row, col) == destination:
            solution[row][col] = True
            return True
        if not (0 <= row < rows and 0 <= col < cols):
            return False
        if maze[row][col] != open_value or solution[row][col]:
            return False

        solution[row][col] = True
        # Python's destination check requires an open cell.
        if variant == PYTHON_VARIANT and (row, col) == destination:
            return True
        for delta_row, delta_col in directions:
            if search(row + delta_row, col + delta_col):
                return True
        solution[row][col] = False
        return False

    if not search(*start):
        return NO_PATH_RESULT, b""

    if variant == PYTHON_VARIANT:
        # Python's solution matrix uses 0 for the route and 1 elsewhere.
        output_words = [0 if solution[row][col] else 1
                        for row in range(rows) for col in range(cols)]
    else:
        # Rust's bool solution matrix serializes true as 1 and false as 0.
        output_words = [int(solution[row][col])
                        for row in range(rows) for col in range(cols)]
    output = struct.pack("<" + "q" * len(output_words), *output_words)

    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, b""
    return len(output), output
