"""Bounded reference oracle for the pinned Java stochastic-matrix predicates."""

from __future__ import annotations

MAX_DIMENSION = 63
MAX_INPUT_VALUES = 3 + MAX_DIMENSION * MAX_DIMENSION
CELL_SCALE = 1_000_000_000_000
MIN_CELL_UNITS = -CELL_SCALE
MAX_CELL_UNITS = CELL_SCALE
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
TOLERANCE = 1e-9
INVALID_RESULT = -1


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    """Return the selected row/column stochastic predicate as 1 or 0."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) < 3
        or len(values) > MAX_INPUT_VALUES
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT

    mode, rows, columns = values[0], values[1], values[2]
    if mode not in (0, 1) or not 1 <= rows <= MAX_DIMENSION or not 1 <= columns <= MAX_DIMENSION:
        return INVALID_RESULT
    if len(values) != 3 + rows * columns:
        return INVALID_RESULT

    cells = values[3:]
    if any(unit < MIN_CELL_UNITS or unit > MAX_CELL_UNITS for unit in cells):
        return INVALID_RESULT

    if mode == 0:
        for row in range(rows):
            total = 0.0
            for column in range(columns):
                value = float(cells[row * columns + column]) / float(CELL_SCALE)
                if value < 0.0:
                    return 0
                total += value
            difference = total - 1.0
            if difference > TOLERANCE or difference < -TOLERANCE:
                return 0
    else:
        for column in range(columns):
            total = 0.0
            for row in range(rows):
                value = float(cells[row * columns + column]) / float(CELL_SCALE)
                if value < 0.0:
                    return 0
                total += value
            difference = total - 1.0
            if difference > TOLERANCE or difference < -TOLERANCE:
                return 0
    return 1
