"""Reference for the bounded Strachey singly-even magic-square profile."""

from __future__ import annotations

import struct

MAX_ORDER = 30
FNV_OFFSET = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1


def square_for(order: int) -> list[list[int]] | None:
    if not 6 <= order <= MAX_ORDER or order % 4 != 2:
        return None

    half = order // 2
    k = half // 2
    block_size = half * half
    odd = [[0] * half for _ in range(half)]
    row, column = 0, half // 2
    odd[row][column] = 1
    for value in range(2, block_size + 1):
        next_row = (row - 1) % half
        next_column = (column + 1) % half
        if odd[next_row][next_column] == 0:
            row, column = next_row, next_column
        else:
            row = (row + 1) % half
        odd[row][column] = value

    square = [[0] * order for _ in range(order)]
    for r in range(half):
        for c in range(half):
            base = odd[r][c]
            square[r][c] = base
            square[r][half + c] = base + 2 * block_size
            square[half + r][c] = base + 3 * block_size
            square[half + r][half + c] = base + block_size

    for r in range(half):
        for c in range(k):
            square[r][c], square[half + r][c] = square[half + r][c], square[r][c]
        for c in range(half - (k - 1), half):
            right_column = half + c
            square[r][right_column], square[half + r][right_column] = (
                square[half + r][right_column], square[r][right_column]
            )

    square[k][0], square[half + k][0] = square[half + k][0], square[k][0]
    square[k][k], square[half + k][k] = square[half + k][k], square[k][k]
    return square


def expected_result(order: int) -> int:
    square = square_for(order)
    if square is None:
        return -1
    stream = bytes((order,)) + b"".join(
        struct.pack("<i", value) for row in square for value in row
    )
    checksum = FNV_OFFSET
    for byte in stream:
        checksum = ((checksum ^ byte) * FNV_PRIME) & MASK64
    return checksum & MASK63
