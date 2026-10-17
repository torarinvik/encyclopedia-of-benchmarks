"""Bounded reference oracle for the pinned Java matrix-sparsity method."""

from __future__ import annotations

MAX_DIMENSION = 63
MAX_INPUT_VALUES = 2 + MAX_DIMENSION * MAX_DIMENSION
MIN_CELL = -1_000_000
MAX_CELL = 1_000_000
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
INVALID_RESULT = -1e300


def expected_result(values: list[int] | tuple[int, ...]) -> float:
    """Return the zero-cell ratio for a bounded rectangular packed matrix."""
    if (
        not isinstance(values, (list, tuple))
        or len(values) < 2
        or len(values) > MAX_INPUT_VALUES
        or any(type(value) is not int or not I64_MIN <= value <= I64_MAX for value in values)
    ):
        return INVALID_RESULT

    rows, columns = values[0], values[1]
    if not 1 <= rows <= MAX_DIMENSION or not 1 <= columns <= MAX_DIMENSION:
        return INVALID_RESULT

    total = rows * columns
    if len(values) != 2 + total:
        return INVALID_RESULT

    cells = values[2:]
    if any(value < MIN_CELL or value > MAX_CELL for value in cells):
        return INVALID_RESULT

    zero_count = sum(value == 0 for value in cells)
    return float(zero_count) / float(total)
