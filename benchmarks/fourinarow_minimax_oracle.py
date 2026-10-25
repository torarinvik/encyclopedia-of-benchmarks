"""Independent bounded oracle for the FreeBench Four-in-a-Row search."""

from __future__ import annotations

MAX_HISTORY = 20
MAX_DEPTH = 7
MAX_INPUT_LENGTH = 4 + MAX_HISTORY
INVALID_RESULT = -1
HUGE = 100_000

_FOUR_VERTICAL = (1 << 0) | (1 << 7) | (1 << 14) | (1 << 21)
_THREE_VERTICAL = _FOUR_VERTICAL >> 7
_TWO_VERTICAL = _THREE_VERTICAL >> 7
_FOUR_HORIZONTAL = 0xF
_THREE_HORIZONTAL = _FOUR_HORIZONTAL >> 1
_TWO_HORIZONTAL = _THREE_HORIZONTAL >> 1
_FOUR_UP_RIGHT = (1 << 0) | (1 << 8) | (1 << 16) | (1 << 24)
_THREE_UP_RIGHT = _FOUR_UP_RIGHT >> 8
_TWO_UP_RIGHT = _THREE_UP_RIGHT >> 8
_FOUR_UP_LEFT = (1 << 3) | (1 << 9) | (1 << 15) | (1 << 21)
_THREE_UP_LEFT = _FOUR_UP_LEFT >> 6
_TWO_UP_LEFT = _THREE_UP_LEFT >> 6


def _contains(board: list[list[int]], player: int, pattern: int, shift: int) -> bool:
    """Test one source mask against a row-major board without using bitboards."""
    remaining = pattern
    bit = 0
    while remaining:
        if remaining & 1:
            cell = bit + shift
            if cell >= 42 or board[cell // 7][cell % 7] != player:
                return False
        remaining >>= 1
        bit += 1
    return True


def _intersects(board: list[list[int]], player: int, pattern: int, shift: int) -> bool:
    remaining = pattern
    bit = 0
    while remaining:
        if remaining & 1:
            cell = bit + shift
            if cell < 42 and board[cell // 7][cell % 7] == player:
                return True
        remaining >>= 1
        bit += 1
    return False


def _score(board: list[list[int]]) -> int:
    total = 0
    for player, opponent, sign in ((1, 2, -1), (2, 1, 1)):
        for shift in range(21):
            if _contains(board, player, _FOUR_VERTICAL, shift):
                total += sign * 1000
        for row in range(6):
            for column in range(4):
                if _contains(board, player, _FOUR_HORIZONTAL, column + row * 6):
                    total += sign * 1000
        for row in range(3):
            for column in range(4):
                shift = column + row * 6
                if _contains(board, player, _FOUR_UP_RIGHT, shift):
                    total += sign * 1000
                if _contains(board, player, _FOUR_UP_LEFT, shift):
                    total += sign * 1000

        for shift in range(21):
            if (_contains(board, player, _THREE_VERTICAL, shift)
                    and not _intersects(board, opponent, _FOUR_VERTICAL, shift)):
                total += sign * 20
        for row in range(6):
            for column in range(5):
                if _contains(board, player, _THREE_HORIZONTAL, column + row * 6):
                    total += sign * 20
        for row in range(3):
            for column in range(4):
                shift = column + row * 6
                if _contains(board, player, _THREE_UP_RIGHT, shift):
                    total += sign * 20
                if _contains(board, player, _THREE_UP_LEFT, shift):
                    total += sign * 20

        for shift in range(21):
            if (_contains(board, player, _TWO_VERTICAL, shift)
                    and not _intersects(board, opponent, _FOUR_VERTICAL, shift)):
                total += sign * 5
        for row in range(6):
            for column in range(6):
                if _contains(board, player, _TWO_HORIZONTAL, column + row * 6):
                    total += sign * 5
        for row in range(3):
            for column in range(4):
                shift = column + row * 6
                if _contains(board, player, _TWO_UP_RIGHT, shift):
                    total += sign * 5
                if _contains(board, player, _TWO_UP_LEFT, shift):
                    total += sign * 5
    return total


def _wins(board: list[list[int]], player: int) -> bool:
    for row in range(6):
        for column in range(7):
            if board[row][column] != player:
                continue
            for dx, dy in ((1, 0), (0, 1), (1, 1), (1, -1)):
                end_x, end_y = column + 3 * dx, row + 3 * dy
                if not (0 <= end_x < 7 and 0 <= end_y < 6):
                    continue
                if all(board[row + step * dy][column + step * dx] == player
                       for step in range(1, 4)):
                    return True
    return False


def _search(board: list[list[int]], side: int, level: int, depth_limit: int,
            alpha_beta: int, alpha: int, beta: int) -> tuple[int, int]:
    if level >= depth_limit:
        return _score(board), 0

    if side == 2:
        best, best_column = -HUGE, 0
        for column in range(7):
            row = next((r for r in range(6) if board[r][column] == 0), None)
            if row is None:
                continue
            child = [line.copy() for line in board]
            child[row][column] = 2
            value, _ = _search(child, 1, level + 1, depth_limit, alpha_beta,
                               best if alpha_beta == 2 else alpha, beta)
            if value > best:
                best, best_column = value, column
            if alpha_beta == 2 and best > beta:
                return best, best_column
        return best, best_column

    best, best_column = HUGE, 0
    for column in range(7):
        row = next((r for r in range(6) if board[r][column] == 0), None)
        if row is None:
            continue
        child = [line.copy() for line in board]
        child[row][column] = 1
        value, _ = _search(child, 2, level + 1, depth_limit, alpha_beta,
                           alpha, best if alpha_beta == 2 else beta)
        if value <= best:
            best, best_column = value, column
        if alpha_beta == 2 and best < alpha:
            return best, best_column
    return best, best_column


def expected_result(values: list[int] | tuple[int, ...] | None) -> int:
    if not isinstance(values, (list, tuple)) or not 4 <= len(values) <= MAX_INPUT_LENGTH:
        return INVALID_RESULT
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return INVALID_RESULT

    depth, alpha_beta, side, move_count = values[:4]
    if not 2 <= depth <= MAX_DEPTH or alpha_beta not in (0, 2):
        return INVALID_RESULT
    if side not in (1, 2) or not 0 <= move_count <= MAX_HISTORY or len(values) != 4 + move_count:
        return INVALID_RESULT
    if side != (1 if move_count % 2 == 0 else 2):
        return INVALID_RESULT

    board = [[0] * 7 for _ in range(6)]
    heights = [0] * 7
    for turn, column in enumerate(values[4:]):
        if not 0 <= column < 7 or heights[column] == 6:
            return INVALID_RESULT
        player = 1 if turn % 2 == 0 else 2
        board[heights[column]][column] = player
        heights[column] += 1
        if _wins(board, player):
            return INVALID_RESULT

    score, column = _search(board, side, 1, depth, alpha_beta, -HUGE, HUGE)
    return score * 8 + column
