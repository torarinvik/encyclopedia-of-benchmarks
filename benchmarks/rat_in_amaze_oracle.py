"""Oracle for the bounded Java and JavaScript rat-in-a-maze variants."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_DIMENSION = 4
MAX_VALID_INPUT_LENGTH = 2 + MAX_DIMENSION * MAX_DIMENSION
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_PATHS = 184
MAX_OUTPUT_WORDS = 1 + MAX_PATHS + 1912
MAX_OUTPUT_BYTES = MAX_OUTPUT_WORDS * 8

INVALID_RESULT = -1
OUTPUT_ERROR = -2
NO_PATH_RESULT = -3

JAVA_VARIANT = 0
JAVASCRIPT_VARIANT = 1


def _invalid() -> tuple[int, bytes]:
    return INVALID_RESULT, b""


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = MAX_OUTPUT_BYTES,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return encoded paths, or the documented ABI status and empty bytes."""
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
    if (
        not 1 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
        or any(
            type(value) is not int or not -(1 << 63) <= value < (1 << 63)
            for value in values
        )
    ):
        return _invalid()

    variant, size = values[:2]
    if variant not in (JAVA_VARIANT, JAVASCRIPT_VARIANT):
        return _invalid()
    if not 1 <= size <= MAX_DIMENSION or len(values) != 2 + size * size:
        return _invalid()
    cells = values[2:]
    if any(cell not in (0, 1) for cell in cells):
        return _invalid()

    goal = size * size - 1
    directions = (
        ((1, 0, 0), (0, -1, 1), (0, 1, 2), (-1, 0, 3))
        if variant == JAVA_VARIANT
        else ((0, 1, 2), (1, 0, 0), (-1, 0, 3), (0, -1, 1))
    )
    visited = [False] * (size * size)
    path: list[int] = []
    paths: list[list[int]] = []

    def search(row: int, col: int) -> bool:
        index = row * size + col
        if index == goal:
            paths.append(path.copy())
            return variant == JAVASCRIPT_VARIANT

        visited[index] = True
        for delta_row, delta_col, code in directions:
            next_row = row + delta_row
            next_col = col + delta_col
            if not (0 <= next_row < size and 0 <= next_col < size):
                continue
            next_index = next_row * size + next_col
            if cells[next_index] != 1 or visited[next_index]:
                continue
            path.append(code)
            found_first = search(next_row, next_col)
            path.pop()
            if found_first:
                visited[index] = False
                return True
        visited[index] = False
        return False

    if cells[0] == 1 and cells[goal] == 1:
        search(0, 0)
    if not paths:
        return NO_PATH_RESULT, b""

    output_words = [len(paths)]
    for route in paths:
        output_words.append(len(route))
        output_words.extend(route)
    output = struct.pack("<" + "q" * len(output_words), *output_words)

    if output_is_null or (
        output_capacity is not None and output_capacity < len(output)
    ):
        return OUTPUT_ERROR, b""
    return len(output), output
