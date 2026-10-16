"""Reference status check for a bounded N-in-a-row square board."""

from __future__ import annotations

MAX_BOARD_SIZE = 16
MAX_INPUT_LENGTH = 2 + MAX_BOARD_SIZE * MAX_BOARD_SIZE


def expected_result(values: list[int]) -> int:
    if (not isinstance(values, list) or len(values) < 2 or len(values) > MAX_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1
    size, player = values[:2]
    if (not 2 <= size <= MAX_BOARD_SIZE or player not in (1, 2)
            or len(values) != 2 + size * size
            or any(cell not in (0, 1, 2) for cell in values[2:])):
        return -1
    board = [values[2 + row * size:2 + (row + 1) * size] for row in range(size)]
    if any(all(cell == player for cell in row) for row in board):
        return 1
    if any(all(board[row][column] == player for row in range(size))
           for column in range(size)):
        return 1
    if all(board[index][index] == player for index in range(size)):
        return 1
    if all(board[index][size - 1 - index] == player for index in range(size)):
        return 1
    return 0 if any(cell == 0 for row in board for cell in row) else 2
