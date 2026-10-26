"""Independent board-rule model for the bounded GNU Go suicide predicate."""
from collections.abc import Sequence

BOARD_SIZE = 19
BOARD_CELLS = 361
MAX_STONES = 120
MAX_INPUT_LENGTH = 6 + 2 * MAX_STONES
INVALID_RESULT = -1


def _group(board: list[int], start: int):
    color = board[start]
    pending = [start]
    stones = {start}
    liberties = set()
    while pending:
        at = pending.pop()
        r, c = divmod(at, BOARD_SIZE)
        neighbors = []
        if r > 0: neighbors.append(at - BOARD_SIZE)
        if r < 18: neighbors.append(at + BOARD_SIZE)
        if c > 0: neighbors.append(at - 1)
        if c < 18: neighbors.append(at + 1)
        for nxt in neighbors:
            if board[nxt] == 0:
                liberties.add(nxt)
            elif board[nxt] == color and nxt not in stones:
                stones.add(nxt)
                pending.append(nxt)
    return stones, liberties


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or len(values) < 6 or len(values) > MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(v) is not int for v in values):
        return INVALID_RESULT
    row, col, own, opponent, ko_index, count = values[:6]
    if (not (0 <= row < 19 and 0 <= col < 19) or own not in (1, 2)
            or opponent not in (1, 2) or own == opponent
            or ko_index < -1 or ko_index >= MAX_STONES
            or count < 0 or count > MAX_STONES or len(values) != 6 + 2 * count):
        return INVALID_RESULT
    board = [0] * BOARD_CELLS
    populated = set()
    for k in range(count):
        index, stone = values[6 + 2 * k:8 + 2 * k]
        if not (0 <= index < BOARD_CELLS and stone in (1, 2)) or index in populated:
            return INVALID_RESULT
        populated.add(index)
        board[index] = stone
    target = row * 19 + col
    if board[target] != 0:
        return INVALID_RESULT
    board[target] = opponent
    _, new_group_liberties = _group(board, target)
    if new_group_liberties:
        return 0

    dead_own_stones = 0
    visited = set()
    for at, stone in enumerate(board):
        if stone == own and at not in visited:
            group, liberties = _group(board, at)
            visited.update(group)
            if not liberties:
                dead_own_stones += len(group)
    if dead_own_stones == 0 or (dead_own_stones == 1 and ko_index == target):
        return 1
    return 0
