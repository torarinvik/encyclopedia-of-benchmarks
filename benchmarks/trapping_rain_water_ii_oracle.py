"""Primary min-heap boundary-flood oracle for two-dimensional rain retention."""

from __future__ import annotations

import heapq
from collections.abc import Sequence

MAX_ROWS = 8
MAX_COLS = 8
MAX_CELLS = MAX_ROWS * MAX_COLS
MAX_INPUT_LENGTH = 2 + MAX_CELLS
MAX_HEIGHT = 1000


def _parse(values: Sequence[int] | None) -> tuple[int, int, list[int]] | None:
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    rows, cols = values[:2]
    if not 1 <= rows <= MAX_ROWS or not 1 <= cols <= MAX_COLS or len(values) != 2 + rows * cols:
        return None
    heights = list(values[2:])
    if any(not 0 <= height <= MAX_HEIGHT for height in heights):
        return None
    return rows, cols, heights


def expected_result(values: Sequence[int] | None) -> int:
    parsed = _parse(values)
    if parsed is None:
        return -1
    rows, cols, heights = parsed
    visited = [False] * len(heights)
    frontier: list[tuple[int, int]] = []
    for row in range(rows):
        for col in range(cols):
            if row == 0 or row + 1 == rows or col == 0 or col + 1 == cols:
                cell = row * cols + col
                if not visited[cell]:
                    visited[cell] = True
                    heapq.heappush(frontier, (heights[cell], cell))

    retained = 0
    while frontier:
        level, cell = heapq.heappop(frontier)
        row, col = divmod(cell, cols)
        for next_row, next_col in ((row - 1, col), (row + 1, col), (row, col - 1), (row, col + 1)):
            if not (0 <= next_row < rows and 0 <= next_col < cols):
                continue
            neighbor = next_row * cols + next_col
            if visited[neighbor]:
                continue
            visited[neighbor] = True
            height = heights[neighbor]
            if height < level:
                retained += level - height
            heapq.heappush(frontier, (max(level, height), neighbor))
    return retained
