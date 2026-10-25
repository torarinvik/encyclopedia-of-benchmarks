"""Independent fixed-point oracle for the bounded SciMark2 SOR grid kernel."""

from __future__ import annotations

MAX_ROWS = 8
MAX_COLS = 8
MAX_INPUT_LENGTH = 3 + MAX_ROWS * MAX_COLS
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1


def _trunc_div(value: int, divisor: int) -> int:
    quotient = abs(value) // divisor
    return -quotient if value < 0 else quotient


def expected_result(values: list[int] | tuple[int, ...] | None) -> int:
    if not isinstance(values, (list, tuple)) or len(values) < 3 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values):
        return INVALID_RESULT
    rows, cols, iterations = values[:3]
    if not 2 <= rows <= MAX_ROWS or not 2 <= cols <= MAX_COLS or not 0 <= iterations <= 8:
        return INVALID_RESULT
    if len(values) != 3 + rows * cols:
        return INVALID_RESULT
    grid = list(values[3:])
    if any(value < -1000 or value > 1000 for value in grid):
        return INVALID_RESULT

    for _ in range(iterations):
        for row in range(1, rows - 1):
            for col in range(1, cols - 1):
                index = row * cols + col
                neighbors = grid[index - cols] + grid[index + cols] + grid[index - 1] + grid[index + 1]
                numerator = 1250 * neighbors - 1000 * grid[index]
                grid[index] = _trunc_div(numerator, 4000)

    return sum((index + 1) * value for index, value in enumerate(grid))


def generated_inputs() -> list[list[int]]:
    return [
        [2, 2, 0, 1000, -1000, 500, -500],
        [3, 3, 1, 0, 0, 0, 0, 1000, 0, 0, 0, 0],
        [4, 4, 1, 0, 0, 0, 0, 0, 1000, 1000, 0, 0, 1000, 1000, 0, 0, 0, 0, 0],
        [5, 3, 2, 0, 1000, 0, 500, -500, 500, -500, 0, 1000, 0, 0, 0, 0, 0, 0, 0],
    ]
