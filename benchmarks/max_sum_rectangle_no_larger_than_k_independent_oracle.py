"""Direct rectangle-cell enumeration reference for the bounded profile."""

from __future__ import annotations

from collections.abc import Sequence

MAX_ROWS = 8
MAX_COLUMNS = 8
CELL_MIN = -16
CELL_MAX = 16
K_MIN = -1024
K_MAX = 1024
NO_FEASIBLE_RESULT = -1025
INVALID_RESULT = -1026
MAX_VALID_INPUT_LENGTH = 3 + MAX_ROWS * MAX_COLUMNS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1


def _parse(values: Sequence[int]) -> tuple[int, int, int, list[list[int]]] | None:
    if len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    height, width, ceiling = values[0], values[1], values[2]
    if height < 1 or height > MAX_ROWS or width < 1 or width > MAX_COLUMNS:
        return None
    if ceiling < K_MIN or ceiling > K_MAX or len(values) != 3 + height * width:
        return None
    rows: list[list[int]] = []
    cursor = 3
    for _ in range(height):
        row: list[int] = []
        for _ in range(width):
            value = values[cursor]
            cursor += 1
            if value < CELL_MIN or value > CELL_MAX:
                return None
            row.append(value)
        rows.append(row)
    return height, width, ceiling, rows


def expected_result(values: Sequence[int]) -> int:
    parsed = _parse(values)
    if parsed is None:
        return INVALID_RESULT
    height, width, ceiling, matrix = parsed
    answer: int | None = None
    for top in range(height):
        for left in range(width):
            for bottom in range(top, height):
                for right in range(left, width):
                    total = 0
                    for row in range(top, bottom + 1):
                        for column in range(left, right + 1):
                            total += matrix[row][column]
                    if total <= ceiling and (answer is None or total > answer):
                        answer = total
    return NO_FEASIBLE_RESULT if answer is None else answer
