"""Rolling pair-of-columns dynamic programming reference."""

from __future__ import annotations

from collections.abc import Sequence

MIN_DIMENSION = 2
MAX_DIMENSION = 6
MAX_CELL_VALUE = 100
MAX_VALID_INPUT_LENGTH = 2 + MAX_DIMENSION * MAX_DIMENSION
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
INVALID_RESULT = -1


def _decode(values: Sequence[int] | None, input_length: int | None) -> list[list[int]] | None:
    if not isinstance(values, (list, tuple)):
        return None
    if input_length is not None and (type(input_length) is not int or input_length != len(values)):
        return None
    if len(values) < 2 + MIN_DIMENSION * MIN_DIMENSION or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    rows, columns = values[0], values[1]
    if not MIN_DIMENSION <= rows <= MAX_DIMENSION or not MIN_DIMENSION <= columns <= MAX_DIMENSION:
        return None
    if len(values) != 2 + rows * columns:
        return None
    flat = values[2:]
    if any(value < 0 or value > MAX_CELL_VALUE for value in flat):
        return None
    return [list(flat[row * columns : (row + 1) * columns]) for row in range(rows)]


def expected_result(values: Sequence[int] | None, input_length: int | None = None) -> int:
    grid = _decode(values, input_length)
    if grid is None:
        return INVALID_RESULT
    rows = len(grid)
    columns = len(grid[0])
    unreachable = -1
    previous = [[unreachable] * columns for _ in range(columns)]
    previous[0][columns - 1] = grid[0][0] + grid[0][columns - 1]
    for row in range(1, rows):
        current = [[unreachable] * columns for _ in range(columns)]
        for left in range(columns):
            for right in range(columns):
                score = previous[left][right]
                if score < 0:
                    continue
                for left_delta in (-1, 0, 1):
                    next_left = left + left_delta
                    if not 0 <= next_left < columns:
                        continue
                    for right_delta in (-1, 0, 1):
                        next_right = right + right_delta
                        if not 0 <= next_right < columns:
                            continue
                        reward = grid[row][next_left]
                        if next_right != next_left:
                            reward += grid[row][next_right]
                        candidate = score + reward
                        if candidate > current[next_left][next_right]:
                            current[next_left][next_right] = candidate
        previous = current
    return max(max(row) for row in previous)


def expected_output(values: Sequence[int] | None, input_length: int | None = None) -> int:
    return expected_result(values, input_length)
