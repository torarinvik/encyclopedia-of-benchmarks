"""Independent row-oriented reference for Zhang-Suen thinning."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
    MAX_COLUMNS,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_ROWS,
    OUTPUT_ERROR_RESULT,
)


def _read_grid(values: Sequence[int] | None, input_is_null: bool,
               input_length: int | None):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    if input_length is not None and (
            type(input_length) is not int or input_length != len(values)):
        return None
    height, width = values[:2]
    if not 1 <= height <= MAX_ROWS or not 1 <= width <= MAX_COLUMNS:
        return None
    if len(values) != 2 + height * width:
        return None
    raw = values[2:]
    if any(pixel not in (0, 1) for pixel in raw):
        return None
    return height, width, tuple(
        tuple(raw[row * width:(row + 1) * width]) for row in range(height)
    )


def _qualifies(grid: tuple[tuple[int, ...], ...], row: int, column: int,
               phase: int) -> bool:
    height, width = len(grid), len(grid[0])
    if row == 0 or column == 0 or row + 1 == height or column + 1 == width:
        return False
    if grid[row][column] == 0:
        return False
    ring = (
        grid[row - 1][column], grid[row - 1][column + 1],
        grid[row][column + 1], grid[row + 1][column + 1],
        grid[row + 1][column], grid[row + 1][column - 1],
        grid[row][column - 1], grid[row - 1][column - 1],
    )
    if not 2 <= sum(ring) <= 6:
        return False
    crossings = sum(
        ring[index] == 0 and ring[(index + 1) % 8] == 1
        for index in range(8)
    )
    if crossings != 1:
        return False
    north, east, south, west = ring[0], ring[2], ring[4], ring[6]
    if phase == 1:
        return not (north and east and south) and not (east and south and west)
    return not (north and east and west) and not (north and south and west)


def expected_output(values: Sequence[int] | None, *, capacity: int,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    parsed = _read_grid(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT, b""
    if type(capacity) is not int or capacity < 0 or type(output_is_null) is not bool:
        return OUTPUT_ERROR_RESULT, b""
    rows, columns, grid = parsed
    if output_is_null or capacity < rows * columns:
        return OUTPUT_ERROR_RESULT, b""

    while True:
        round_changed = False
        for phase in (1, 2):
            removed = tuple(
                (row, column)
                for row in range(1, rows - 1)
                for column in range(1, columns - 1)
                if _qualifies(grid, row, column, phase)
            )
            if removed:
                updated = [list(line) for line in grid]
                for row, column in removed:
                    updated[row][column] = 0
                grid = tuple(tuple(line) for line in updated)
                round_changed = True
        if not round_changed:
            break
    return rows * columns, bytes(pixel for line in grid for pixel in line)
