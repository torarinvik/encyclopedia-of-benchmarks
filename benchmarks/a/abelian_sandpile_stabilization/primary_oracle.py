"""Deterministic legal-toppling queue for bounded Abelian sandpile frames."""

from __future__ import annotations

from collections import deque
from collections.abc import Sequence

MAX_ROWS = 4
MAX_COLS = 4
MAX_HEIGHT = 31
MAX_VALID_INPUT_LENGTH = 18
MAX_PARSEABLE_INPUT_LENGTH = 19
MAX_TOPPLES = 1_488
MAX_RESULT = (4 ** 16) - 1
INVALID_RESULT = -1


def _parse(values: Sequence[int] | None, input_is_null: bool,
           input_length: int | None) -> tuple[int, int, list[int]] | None:
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(word) is not int or not -(1 << 63) <= word < (1 << 63)
                   for word in values)):
        return None
    actual_length = len(values) if input_length is None else input_length
    if type(actual_length) is not int or actual_length != len(values):
        return None
    rows, cols = values[0], values[1]
    if not 1 <= rows <= MAX_ROWS or not 1 <= cols <= MAX_COLS:
        return None
    if len(values) != 2 + rows * cols:
        return None
    cells = list(values[2:])
    if any(height < 0 or height > MAX_HEIGHT for height in cells):
        return None
    return rows, cols, cells


def _pack(cells: Sequence[int]) -> int:
    result = 0
    place = 1
    for height in cells:
        result += height * place
        place *= 4
    return result


def _stabilize_queue(rows: int, cols: int, cells: list[int]) -> list[int]:
    count = rows * cols
    board = cells.copy()
    queue: deque[int] = deque()
    queued = [False] * count

    def enqueue(site: int) -> None:
        if board[site] >= 4 and not queued[site]:
            queue.append(site)
            queued[site] = True

    for site in range(count):
        enqueue(site)

    topple_count = 0
    while queue:
        site = queue.popleft()
        queued[site] = False
        if board[site] < 4:
            continue
        row, col = divmod(site, cols)
        board[site] -= 4
        topple_count += 1
        if topple_count > MAX_TOPPLES:
            return []
        # Fixed N, E, S, W neighbor order. Missing neighbors are sink edges.
        neighbors: list[int] = []
        if row > 0:
            neighbors.append(site - cols)
        if col + 1 < cols:
            neighbors.append(site + 1)
        if row + 1 < rows:
            neighbors.append(site + cols)
        if col > 0:
            neighbors.append(site - 1)
        for neighbor in neighbors:
            board[neighbor] += 1
            enqueue(neighbor)
        enqueue(site)
    return board


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the packed stable board, or -1 for invalid framing or values."""
    parsed = _parse(values, input_is_null, input_length)
    if parsed is None:
        return INVALID_RESULT
    rows, cols, cells = parsed
    board = _stabilize_queue(rows, cols, cells)
    if not board and rows * cols != 0:
        return INVALID_RESULT
    return _pack(board)
