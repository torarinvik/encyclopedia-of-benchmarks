"""Independent modular-formula reference with square-invariant checks."""

from __future__ import annotations

import struct

MAX_ORDER = 30
FNV_OFFSET = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1


def _odd_cell(row: int, column: int, side: int) -> int:
    """Invert the Siamese walk's modular coordinates to get a cell value."""
    center = side // 2
    diagonal = (row + column - center) % side
    step = (column - center + diagonal) % side
    return diagonal * side + step + 1


def square_for(order: int) -> list[list[int]] | None:
    if order < 6 or order > MAX_ORDER or order % 4 != 2:
        return None

    side = order // 2
    midpoint = side // 2
    block_size = side * side
    square = [[0] * order for _ in range(order)]

    # Build all four translated odd squares directly from their coordinates.
    for row in range(side):
        for column in range(side):
            value = _odd_cell(row, column, side)
            square[row][column] = value
            square[row][side + column] = value + 2 * block_size
            square[side + row][column] = value + 3 * block_size
            square[side + row][side + column] = value + block_size

    # Apply the Strachey exchanges by their block coordinates.
    for row in range(side):
        for column in range(midpoint):
            upper = square[row][column]
            square[row][column] = square[side + row][column]
            square[side + row][column] = upper
        for column in range(side - midpoint + 1, side):
            upper_column = side + column
            upper = square[row][upper_column]
            square[row][upper_column] = square[side + row][upper_column]
            square[side + row][upper_column] = upper

    upper = square[midpoint][0]
    square[midpoint][0] = square[side + midpoint][0]
    square[side + midpoint][0] = upper
    upper = square[midpoint][midpoint]
    square[midpoint][midpoint] = square[side + midpoint][midpoint]
    square[side + midpoint][midpoint] = upper
    return square


def _is_normal_magic_square(square: list[list[int]]) -> bool:
    order = len(square)
    target = order * (order * order + 1) // 2
    flattened = [value for row in square for value in row]
    if sorted(flattened) != list(range(1, order * order + 1)):
        return False
    if any(sum(row) != target for row in square):
        return False
    if any(sum(square[row][column] for row in range(order)) != target for column in range(order)):
        return False
    return (
        sum(square[i][i] for i in range(order)) == target
        and sum(square[i][order - i - 1] for i in range(order)) == target
    )


def expected_result(order: int) -> int:
    square = square_for(order)
    if square is None:
        return -1
    if not _is_normal_magic_square(square):
        raise AssertionError("constructed square violates the normal magic-square invariants")
    payload = bytearray((order,))
    for row in square:
        for value in row:
            payload.extend(struct.pack("<i", value))
    checksum = FNV_OFFSET
    for byte in payload:
        checksum = ((checksum ^ byte) * FNV_PRIME) & MASK64
    return checksum & MASK63
