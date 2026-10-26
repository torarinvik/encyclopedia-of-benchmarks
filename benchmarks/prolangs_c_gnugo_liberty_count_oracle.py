"""Independent reference for the bounded GNU Go group-liberty profile."""
from collections.abc import Sequence

BOARD_SIZE = 19
MAX_STONES = BOARD_SIZE * BOARD_SIZE
MAX_INPUT_LENGTH = 4 + 2 * MAX_STONES
INVALID_RESULT = -1


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or len(values) < 4 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(v) is not int for v in values):
        return INVALID_RESULT
    row, col, color, count = values[:4]
    if not (0 <= row < 19 and 0 <= col < 19 and color in (1, 2)
            and 0 <= count <= MAX_STONES and len(values) == 4 + 2 * count):
        return INVALID_RESULT
    board = [0] * MAX_STONES
    populated = set()
    for k in range(count):
        index, stone = values[4 + 2 * k:6 + 2 * k]
        if not (0 <= index < MAX_STONES and stone in (1, 2)) or index in populated:
            return INVALID_RESULT
        populated.add(index)
        board[index] = stone
    start = row * 19 + col
    if board[start] != color:
        return INVALID_RESULT
    visited_stones = {start}
    liberties = set()
    pending = [start]
    while pending:
        at = pending.pop()
        r, c = divmod(at, 19)
        neighbors = []
        if r: neighbors.append(at - 19)
        if r < 18: neighbors.append(at + 19)
        if c: neighbors.append(at - 1)
        if c < 18: neighbors.append(at + 1)
        for nxt in neighbors:
            if board[nxt] == 0:
                liberties.add(nxt)
            elif board[nxt] == color and nxt not in visited_stones:
                visited_stones.add(nxt)
                pending.append(nxt)
    return len(liberties)
