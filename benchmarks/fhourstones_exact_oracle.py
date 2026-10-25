"""Independent exhaustive oracle for the bounded Fhourstones endgame."""

from __future__ import annotations

from typing import Sequence

WIDTH = 7
HEIGHT = 6
BOARD_CELLS = WIDTH * HEIGHT
MIN_MOVES = 36
MAX_MOVES = 41
MAX_INPUT_LENGTH = MAX_MOVES + 1
INVALID_RESULT = -1
MOVE_ORDER = (3, 2, 4, 1, 5, 0, 6)
DIRECTIONS = ((1, 0), (0, 1), (1, 1), (1, -1))


def _wins_at(board: list[list[int]], column: int, row: int, side: int) -> bool:
    for dx, dy in DIRECTIONS:
        count = 1
        for sign in (-1, 1):
            for distance in range(1, 4):
                x = column + sign * distance * dx
                y = row + sign * distance * dy
                if not (0 <= x < WIDTH and 0 <= y < HEIGHT):
                    break
                if board[y][x] != side:
                    break
                count += 1
        if count >= 4:
            return True
    return False


def _exhaustive_outcome(
    board: list[list[int]], heights: list[int], side: int, remaining: int
) -> int:
    """Return exact WDL by full minimax without alpha-beta pruning."""
    if remaining == 0:
        return 0

    best = -3
    for column in MOVE_ORDER:
        row = heights[column]
        if row == HEIGHT:
            continue
        board[row][column] = side
        heights[column] += 1
        if _wins_at(board, column, row, side):
            value = 2
        else:
            next_side = 2 if side == 1 else 1
            value = -_exhaustive_outcome(board, heights, next_side, remaining - 1)
        heights[column] -= 1
        board[row][column] = 0
        if value > best:
            best = value
    return best


def expected_result(values: Sequence[int] | None) -> int:
    if not isinstance(values, (list, tuple)) or not 2 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(
        type(value) is not int or not -(1 << 63) <= value < (1 << 63)
        for value in values
    ):
        return INVALID_RESULT

    move_count = values[0]
    if not MIN_MOVES <= move_count <= MAX_MOVES or len(values) != move_count + 1:
        return INVALID_RESULT

    board = [[0] * WIDTH for _ in range(HEIGHT)]
    heights = [0] * WIDTH
    for turn, column in enumerate(values[1:]):
        if not 0 <= column < WIDTH or heights[column] == HEIGHT:
            return INVALID_RESULT
        side = 1 if turn % 2 == 0 else 2
        row = heights[column]
        board[row][column] = side
        heights[column] += 1
        if _wins_at(board, column, row, side):
            return INVALID_RESULT

    side_to_move = 1 if move_count % 2 == 0 else 2
    return _exhaustive_outcome(
        board, heights, side_to_move, BOARD_CELLS - move_count
    )
