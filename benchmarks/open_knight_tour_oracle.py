"""Oracle for the common-success dimensions of the open knight-tour search."""

from __future__ import annotations

from collections.abc import Sequence
import struct

MAX_INPUT_LENGTH = 1
MAX_OUTPUT_BYTES = 100
ALLOWED_SIZES = (1, 5)
INVALID_RESULT = -1
OUTPUT_ERROR = -2
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1
_DR = (1, -1, 1, -1, 2, 2, -2, -2)
_DC = (2, 2, -2, -2, 1, -1, 1, -1)


def _solve(board: list[list[int]], n: int, row: int, col: int, step: int) -> bool:
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


def expected_output(
    values: Sequence[int] | None,
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    """Return the deterministic row-major tour board or an ABI status."""
    if type(output_is_null) is not bool or type(input_is_null) is not bool:
        return INVALID_RESULT, b""
    if output_capacity is not None and (
        type(output_capacity) is not int or output_capacity < 0
    ):
        return INVALID_RESULT, b""
    if input_length is not None and (
        type(input_length) is not int or input_length < 0
    ):
        return INVALID_RESULT, b""
    if input_is_null or values is None or not isinstance(values, (list, tuple)):
        return INVALID_RESULT, b""
    if input_length is not None and input_length != len(values):
        return INVALID_RESULT, b""
    if len(values) != MAX_INPUT_LENGTH:
        return INVALID_RESULT, b""
    if type(values[0]) is not int or not I64_MIN <= values[0] <= I64_MAX:
        return INVALID_RESULT, b""

    n = values[0]
    if n not in ALLOWED_SIZES:
        return INVALID_RESULT, b""
    board = [[0] * n for _ in range(n)]
    found = False
    for row in range(n):
        for col in range(n):
            board[row][col] = 1
            if _solve(board, n, row, col, 1):
                found = True
                break
            board[row][col] = 0
        if found:
            break
    if not found:
        return INVALID_RESULT, b""

    flat_board = [value for row in board for value in row]
    encoded = struct.pack("<" + "i" * len(flat_board), *flat_board)
    if len(encoded) > MAX_OUTPUT_BYTES:
        return INVALID_RESULT, b""
    if output_is_null or (
        output_capacity is not None and output_capacity < len(encoded)
    ):
        return OUTPUT_ERROR, b""
    return len(encoded), encoded
