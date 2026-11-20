"""Exhaustive paired-path enumeration independent of the rolling DP."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
    MAX_CELL_VALUE,
    MAX_DIMENSION,
    MAX_PARSEABLE_INPUT_LENGTH,
    MIN_DIMENSION,
)


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
    best = -1

    def enumerate_paths(row: int, left: int, right: int, score: int) -> None:
        nonlocal best
        if row == rows - 1:
            best = max(best, score)
            return
        for left_delta in (-1, 0, 1):
            next_left = left + left_delta
            if not 0 <= next_left < columns:
                continue
            for right_delta in (-1, 0, 1):
                next_right = right + right_delta
                if not 0 <= next_right < columns:
                    continue
                reward = grid[row + 1][next_left]
                if next_left != next_right:
                    reward += grid[row + 1][next_right]
                enumerate_paths(row + 1, next_left, next_right, score + reward)

    initial = grid[0][0] + grid[0][columns - 1]
    enumerate_paths(0, 0, columns - 1, initial)
    return best


def expected_output(values: Sequence[int] | None, input_length: int | None = None) -> int:
    return expected_result(values, input_length)
