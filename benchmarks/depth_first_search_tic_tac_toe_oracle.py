"""Bounded oracle for the Rust tic-tac-toe minimax search."""

from __future__ import annotations

from functools import lru_cache

INVALID_RESULT = -1
BOARD_CELLS = 9
ENCODING_STRIDE = 1 << BOARD_CELLS


def _won(board: tuple[int, ...], player: int) -> bool:
    lines = ((0, 1, 2), (3, 4, 5), (6, 7, 8),
             (0, 3, 6), (1, 4, 7), (2, 5, 8),
             (0, 4, 8), (2, 4, 6))
    return any(all(board[index] == player for index in line) for line in lines)


@lru_cache(maxsize=None)
def _search(board: tuple[int, ...], side: int) -> tuple[int, int] | None:
    if _won(board, 1) or _won(board, 2):
        return None
    available = [index for index, value in enumerate(board) if value == 0]
    if not available:
        return None
    other = 3 - side
    best_score = 0
    best_rank = -1
    best_mask = 0
    for index in available:
        next_board = list(board)
        next_board[index] = side
        frozen = tuple(next_board)
        if _won(frozen, 1):
            score = 1
        elif _won(frozen, 2):
            score = 2
        else:
            result = _search(frozen, other)
            score = result[0] if result is not None else 0
        rank = 2 if score == side else (1 if score == 0 else 0)
        if rank > best_rank:
            best_rank, best_score, best_mask = rank, score, 1 << index
        elif rank == best_rank:
            best_mask |= 1 << index
    return best_score, best_mask


def expected_result(values: list[int] | tuple[int, ...]) -> int:
    if (not isinstance(values, (list, tuple)) or len(values) != 10
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return INVALID_RESULT
    side, *cells = values
    if side not in (1, 2) or any(value not in (0, 1, 2) for value in cells):
        return INVALID_RESULT
    result = _search(tuple(cells), side)
    if result is None:
        return 0
    score, mask = result
    return 1 + score * ENCODING_STRIDE + mask
