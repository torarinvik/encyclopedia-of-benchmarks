"""Reference oracle for the bounded ASCII matrix-based removal game."""

from __future__ import annotations

MAX_INPUT_LENGTH = 194
MAX_DIMENSION = 8
MAX_MOVES = 64
EMPTY = -1


def _is_ascii_alphanumeric(value: int) -> bool:
    return 48 <= value <= 57 or 65 <= value <= 90 or 97 <= value <= 122


def expected_result(values: list[int]) -> int:
    if (
        not isinstance(values, list)
        or len(values) < 2
        or len(values) > MAX_INPUT_LENGTH
        or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values)
    ):
        return -1

    n = values[0]
    if not 1 <= n <= MAX_DIMENSION:
        return -1
    cells = n * n
    move_count_index = 1 + cells
    if len(values) < move_count_index + 1:
        return -1
    move_count = values[move_count_index]
    if not 0 <= move_count <= MAX_MOVES:
        return -1
    if len(values) != 2 + cells + 2 * move_count:
        return -1

    symbols = values[1:move_count_index]
    if any(not _is_ascii_alphanumeric(symbol) for symbol in symbols):
        return -1
    moves = [
        (values[move_count_index + 1 + 2 * index], values[move_count_index + 2 + 2 * index])
        for index in range(move_count)
    ]
    if any(not (0 <= x < n and 0 <= y < n) for x, y in moves):
        return -1

    board = [symbols[row * n : (row + 1) * n] for row in range(n)]
    total_score = 0
    for x, y in moves:
        start_row = n - 1 - y
        color = board[start_row][x]
        if color == EMPTY:
            continue

        stack = [(start_row, x)]
        visited = {(start_row, x)}
        component: list[tuple[int, int]] = []
        while stack:
            row, col = stack.pop()
            component.append((row, col))
            for next_row, next_col in ((row - 1, col), (row + 1, col), (row, col - 1), (row, col + 1)):
                if (
                    0 <= next_row < n
                    and 0 <= next_col < n
                    and (next_row, next_col) not in visited
                    and board[next_row][next_col] == color
                ):
                    visited.add((next_row, next_col))
                    stack.append((next_row, next_col))

        count = len(component)
        total_score += count * (count + 1) // 2
        for row, col in component:
            board[row][col] = EMPTY

        for col in range(n):
            retained = [board[row][col] for row in range(n) if board[row][col] != EMPTY]
            board_column = [EMPTY] * (n - len(retained)) + retained
            for row in range(n):
                board[row][col] = board_column[row]

        empty_columns = [
            col for col in range(n - 1, -1, -1) if all(board[row][col] == EMPTY for row in range(n))
        ]
        for col in empty_columns:
            for source_col in range(col + 1, n):
                for row in range(n):
                    board[row][source_col - 1] = board[row][source_col]
            for row in range(n):
                board[row][n - 1] = EMPTY

    return total_score
