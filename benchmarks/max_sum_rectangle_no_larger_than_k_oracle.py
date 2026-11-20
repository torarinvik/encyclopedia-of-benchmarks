"""Band-compression and prefix-successor reference for the bounded profile."""

from __future__ import annotations

from bisect import bisect_left, insort
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


def _matrix(values: Sequence[int]) -> tuple[int, int, int, list[list[int]]] | None:
    if len(values) < 3 or len(values) > MAX_PARSEABLE_INPUT_LENGTH:
        return None
    rows, columns, limit = values[0], values[1], values[2]
    if not (1 <= rows <= MAX_ROWS and 1 <= columns <= MAX_COLUMNS):
        return None
    if not (K_MIN <= limit <= K_MAX) or len(values) != 3 + rows * columns:
        return None
    cells = values[3:]
    if any(value < CELL_MIN or value > CELL_MAX for value in cells):
        return None
    matrix = [list(cells[row * columns:(row + 1) * columns]) for row in range(rows)]
    return rows, columns, limit, matrix


def _best_subarray_at_most(values: Sequence[int], limit: int) -> int | None:
    """Return the best nonempty subarray sum at most limit, if one exists."""
    prefixes = [0]
    running = 0
    best: int | None = None
    for value in values:
        running += value
        position = bisect_left(prefixes, running - limit)
        if position < len(prefixes):
            candidate = running - prefixes[position]
            if best is None or candidate > best:
                best = candidate
        insort(prefixes, running)
    return best


def expected_result(values: Sequence[int]) -> int:
    parsed = _matrix(values)
    if parsed is None:
        return INVALID_RESULT
    rows, columns, limit, matrix = parsed
    if rows <= columns:
        short, long = rows, columns
        at = lambda band, offset: matrix[band][offset]
    else:
        short, long = columns, rows
        at = lambda band, offset: matrix[offset][band]
    best: int | None = None
    for first in range(short):
        compressed = [0] * long
        for last in range(first, short):
            for offset in range(long):
                compressed[offset] += at(last, offset)
            candidate = _best_subarray_at_most(compressed, limit)
            if candidate is not None and (best is None or candidate > best):
                best = candidate
                if best == limit:
                    return best
    return NO_FEASIBLE_RESULT if best is None else best
