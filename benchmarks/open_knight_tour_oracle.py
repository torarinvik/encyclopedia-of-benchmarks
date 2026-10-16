"""Runtime oracle for the bounded row-major open knight-tour backtracker."""
import struct

MAX_INPUT_LENGTH = 1
MAX_OUTPUT_BYTES = 100
_DR = (1, -1, 1, -1, 2, 2, -2, -2)
_DC = (2, 2, -2, -2, 1, -1, 1, -1)


def _solve(board, n, row, col, step):
    if step == n * n:
        return True
    for dr, dc in zip(_DR, _DC):
        nr, nc = row + dr, col + dc
        if 0 <= nr < n and 0 <= nc < n and board[nr][nc] == 0:
            board[nr][nc] = step + 1
            if _solve(board, n, nr, nc, step + 1):
                return True
            board[nr][nc] = 0
    return False


def expected_output(values):
    if (not isinstance(values, (list, tuple)) or len(values) != 1
            or type(values[0]) is not int or not 1 <= values[0] <= 5):
        return -1, b""
    n = values[0]
    board = [[0] * n for _ in range(n)]
    for row in range(n):
        for col in range(n):
            board[row][col] = 1
            if _solve(board, n, row, col, 1):
                payload = struct.pack("<" + "i" * (n * n), *(x for line in board for x in line))
                return len(payload), payload
            board[row][col] = 0
    payload = struct.pack("<" + "i" * (n * n), *(x for line in board for x in line))
    return len(payload), payload
