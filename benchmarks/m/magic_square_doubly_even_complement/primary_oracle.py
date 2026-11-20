"""Cellwise reference for the bounded doubly-even magic-square profile."""

from __future__ import annotations

import struct

MIN_ORDER = 4
MAX_ORDER = 64
FNV_OFFSET = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1


def square_for(order: int) -> list[list[int]] | None:
    if not MIN_ORDER <= order <= MAX_ORDER or order % 4:
        return None

    square_cells = order * order
    rows: list[list[int]] = []
    for row in range(order):
        values: list[int] = []
        for column in range(order):
            value = row * order + column + 1
            local_row = row % 4
            local_column = column % 4
            if local_row == local_column or local_row + local_column == 3:
                value = square_cells + 1 - value
            values.append(value)
        rows.append(values)
    return rows


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
