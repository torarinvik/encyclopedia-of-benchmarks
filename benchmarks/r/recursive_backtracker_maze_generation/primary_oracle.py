"""Iterative-stack recursive-backtracker reference."""

from __future__ import annotations

from collections.abc import Sequence

INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_CELLS = 64
MAX_VALID_INPUT_LENGTH = 67
MAX_PARSEABLE_INPUT_LENGTH = 68
MAX_OUTPUT_BYTES = 64
WORKSPACE_BYTES = 1024
NORTH, EAST, SOUTH, WEST = 1, 2, 4, 8
WALL_BITS = (NORTH, EAST, SOUTH, WEST)
OPPOSITE_BITS = (SOUTH, WEST, NORTH, EAST)


def _decode(values: Sequence[int], input_is_null: bool,
            input_length: int) -> tuple[int, int, int, tuple[int, ...]] | None:
    if (not isinstance(values, (tuple, list)) or type(input_is_null) is not bool
            or input_is_null or type(input_length) is not int
            or input_length != len(values)
            or input_length < 4 or input_length > MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return None
    rows, cols, start, draw_count = values[:4]
    if not 1 <= rows <= MAX_CELLS or not 1 <= cols <= MAX_CELLS:
        return None
    cells = rows * cols
    if cells > MAX_CELLS or not 0 <= start < cells:
        return None
    if draw_count != cells - 1 or input_length != 4 + draw_count:
        return None
    draws = tuple(values[4:])
    if any(not 0 <= draw <= 3 for draw in draws):
        return None
    return rows, cols, start, draws


def _generate(rows: int, cols: int, start: int,
              draws: tuple[int, ...]) -> bytes | None:
    cells = rows * cols
    visited = [False] * cells
    walls = [15] * cells
    stack = [start]
    visited[start] = True
    cursor = 0
    directions: tuple[tuple[int, int], ...] = ((-1, 0), (0, 1), (1, 0), (0, -1))

    while stack:
        cell = stack[-1]
        row, col = divmod(cell, cols)
        options: list[tuple[int, int]] = []
        for direction, (dr, dc) in enumerate(directions):
            nr, nc = row + dr, col + dc
            if 0 <= nr < rows and 0 <= nc < cols:
                neighbor = nr * cols + nc
                if not visited[neighbor]:
                    options.append((neighbor, direction))
        if not options:
            stack.pop()
            continue
        if cursor >= len(draws):
            return None
        choice = draws[cursor]
        if choice >= len(options):
            return None
        cursor += 1
        neighbor, direction = options[choice]
        visited[neighbor] = True
        walls[cell] &= ~WALL_BITS[direction]
        walls[neighbor] &= ~OPPOSITE_BITS[direction]
        stack.append(neighbor)

    if cursor != len(draws) or not all(visited):
        return None
    return bytes(walls)


def expected_output(values: Sequence[int], capacity: int | None = MAX_OUTPUT_BYTES,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    actual_length = (len(values) if input_length is None and isinstance(values, (tuple, list))
                     else input_length)
    if actual_length is None:
        return INVALID_RESULT, b""
    decoded = _decode(values, input_is_null, actual_length)
    if decoded is None:
        return INVALID_RESULT, b""
    generated = _generate(*decoded)
    if generated is None:
        return INVALID_RESULT, b""
    if (type(output_is_null) is not bool
            or (capacity is not None and (type(capacity) is not int or capacity < 0))):
        return INVALID_RESULT, b""
    if output_is_null or (capacity is not None and capacity < len(generated)):
        return OUTPUT_ERROR, b""
    return len(generated), generated
