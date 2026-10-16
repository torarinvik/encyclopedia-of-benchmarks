"""Reference for recursive tromino tiling of a power-of-two board."""
from __future__ import annotations
import struct

MAX_SIZE = 16


def expected_output(values: list[int]) -> tuple[int, bytes]:
    if (not isinstance(values, list) or len(values) != 3
            or any(type(v) is not int or not -(2**63) <= v < 2**63 for v in values)):
        return -1, b""
    size, hole_row, hole_col = values
    if (size < 1 or size > MAX_SIZE or size & (size - 1)
            or not 0 <= hole_row < size or not 0 <= hole_col < size):
        return -1, b""
    board = [[0] * size for _ in range(size)]
    next_tile = 1

    def fill(width: int, row: int, col: int, missing_row: int, missing_col: int) -> None:
        nonlocal next_tile
        if width == 1:
            return
        half = width // 2
        tile = next_tile
        next_tile += 1
        # Quadrants are processed in source order: top-left, top-right,
        # bottom-left, bottom-right. The center L covers each non-hole quadrant.
        quadrants = (
            (row, col, row + half - 1, col + half - 1),
            (row, col + half, row + half - 1, col + half),
            (row + half, col, row + half, col + half - 1),
            (row + half, col + half, row + half, col + half),
        )
        missing_q = (0 if missing_row < row + half and missing_col < col + half else
                     1 if missing_row < row + half else
                     2 if missing_col < col + half else 3)
        for q, (qr, qc, center_r, center_c) in enumerate(quadrants):
            if q == missing_q:
                next_r, next_c = missing_row, missing_col
            else:
                board[center_r][center_c] = tile
                next_r, next_c = center_r, center_c
            fill(half, qr, qc, next_r, next_c)

    fill(size, 0, 0, hole_row, hole_col)
    payload = b"".join(struct.pack("<i", value) for row in board for value in row)
    return len(payload), payload
