"""Independent reference for the bounded odd-order Siamese magic square."""

from __future__ import annotations

import struct

MAX_ORDER = 31
FNV_OFFSET = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1


def expected_result(order: int) -> int:
    """Return the source-shaped square's low-63-bit FNV-1a checksum."""
    if not 1 <= order <= MAX_ORDER or order % 2 == 0:
        return -1

    square = [[0] * order for _ in range(order)]
    row, column = order // 2, order - 1
    square[row][column] = 1
    for value in range(2, order * order + 1):
        next_row = (row - 1 + order) % order
        next_column = (column + 1) % order
        if square[next_row][next_column] == 0:
            row, column = next_row, next_column
        else:
            column = (column - 1 + order) % order
        square[row][column] = value

    checksum = FNV_OFFSET
    stream = bytes((order,)) + b"".join(
        struct.pack("<i", square_row[column_index])
        for square_row in square
        for column_index in range(order)
    )
    for byte in stream:
        checksum = ((checksum ^ byte) * FNV_PRIME) & MASK64
    return checksum & MASK63
