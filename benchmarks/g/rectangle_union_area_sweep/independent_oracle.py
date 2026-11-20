"""Unit-cell reference for small integer-coordinate rectangle inputs."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_RECTANGLES,
    MIN_COORDINATE,
    MAX_COORDINATE,
)

MAX_GRID_COORDINATE = 32


def expected_result(values: Sequence[int], input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    if input_is_null or not isinstance(values, (list, tuple)):
        return -1
    actual_length = len(values) if input_length is None else input_length
    if (type(actual_length) is not int or actual_length != len(values)
            or not 1 <= actual_length <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    count = values[0]
    if type(count) is not int or not 0 <= count <= MAX_RECTANGLES:
        return -1
    if actual_length != 1 + 4 * count:
        return -1

    covered_cells: set[tuple[int, int]] = set()
    for offset in range(1, actual_length, 4):
        x1, y1, x2, y2 = values[offset:offset + 4]
        if (not MIN_COORDINATE <= x1 <= MAX_COORDINATE
                or not MIN_COORDINATE <= y1 <= MAX_COORDINATE
                or not MIN_COORDINATE <= x2 <= MAX_COORDINATE
                or not MIN_COORDINATE <= y2 <= MAX_COORDINATE
                or x1 >= x2 or y1 >= y2):
            return -1
        if (min(x1, y1, x2, y2) < -MAX_GRID_COORDINATE
                or max(x1, y1, x2, y2) > MAX_GRID_COORDINATE):
            raise ValueError("unit-cell oracle accepts only coordinates in [-32, 32]")
        for x in range(x1, x2):
            for y in range(y1, y2):
                covered_cells.add((x, y))
    return len(covered_cells)
