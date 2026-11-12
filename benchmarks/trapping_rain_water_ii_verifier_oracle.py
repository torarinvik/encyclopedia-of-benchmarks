"""Independent per-cell threshold-reachability oracle for terrain escape levels."""

from __future__ import annotations

from bisect import bisect_left
from collections import deque
from collections.abc import Sequence

MAX_ROWS = 8
MAX_COLS = 8
MAX_INPUT_LENGTH = 2 + MAX_ROWS * MAX_COLS
MAX_HEIGHT = 1000


def _read(values: Sequence[int] | None) -> tuple[int, int, list[int]] | None:
    if values is None or not isinstance(values, (tuple, list)) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH:
        return None
    for value in values:
        if type(value) is not int or value < -(1 << 63) or value >= (1 << 63):
            return None
    r, c = values[0], values[1]
    if r < 1 or r > MAX_ROWS or c < 1 or c > MAX_COLS or len(values) - 2 != r * c:
        return None
    heights = [values[i] for i in range(2, len(values))]
    if any(height < 0 or height > MAX_HEIGHT for height in heights):
        return None
    return r, c, heights


def _can_escape(rows: int, cols: int, heights: list[int], start: int, ceiling: int) -> bool:
    if heights[start] > ceiling:
        return False
    reached = [False] * len(heights)
    reached[start] = True
    queue = deque([start])
    while queue:
        cell = queue.popleft()
        row, col = divmod(cell, cols)
        if row == 0 or row + 1 == rows or col == 0 or col + 1 == cols:
            return True
        for nr, nc in ((row - 1, col), (row + 1, col), (row, col - 1), (row, col + 1)):
            if 0 <= nr < rows and 0 <= nc < cols:
                neighbor = nr * cols + nc
                if not reached[neighbor] and heights[neighbor] <= ceiling:
                    reached[neighbor] = True
                    queue.append(neighbor)
    return False


def expected_result(values: Sequence[int] | None) -> int:
    parsed = _read(values)
    if parsed is None:
        return -1
    rows, cols, heights = parsed
    elevations = sorted(set(heights))
    total = 0
    for row in range(1, rows - 1):
        for col in range(1, cols - 1):
            cell = row * cols + col
            low = bisect_left(elevations, heights[cell])
            high = len(elevations) - 1
            while low < high:
                middle = (low + high) // 2
                if _can_escape(rows, cols, heights, cell, elevations[middle]):
                    high = middle
                else:
                    low = middle + 1
            total += elevations[low] - heights[cell]
    return total
