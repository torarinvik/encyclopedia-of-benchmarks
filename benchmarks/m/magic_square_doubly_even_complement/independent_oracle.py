"""Mask-table construction and normal-square checks for the bounded profile."""

from __future__ import annotations

import struct

MIN_ORDER = 4
MAX_ORDER = 64
FNV_OFFSET = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3
MASK64 = (1 << 64) - 1
MASK63 = (1 << 63) - 1
COMPLEMENT_COLUMNS = (0b1001, 0b0110, 0b0110, 0b1001)


def square_for(order: int) -> list[list[int]] | None:
    if order < MIN_ORDER or order > MAX_ORDER or order & 3:
        return None

    ceiling = order * order + 1
    square: list[list[int]] = []
    for row in range(order):
        mask = COMPLEMENT_COLUMNS[row & 3]
        current: list[int] = []
        for column in range(order):
            value = row * order + column + 1
            if mask & (1 << (column & 3)):
                value = ceiling - value
            current.append(value)
        square.append(current)
    return square


def _is_normal_magic_square(square: list[list[int]]) -> bool:
    order = len(square)
    target = order * (order * order + 1) // 2
    flat = [value for row in square for value in row]
    if sorted(flat) != list(range(1, order * order + 1)):
        return False
    if any(sum(row) != target for row in square):
        return False
    if any(sum(square[row][column] for row in range(order)) != target for column in range(order)):
        return False
    return (
        sum(square[index][index] for index in range(order)) == target
        and sum(square[index][order - index - 1] for index in range(order)) == target
    )


def expected_result(order: int) -> int:
    square = square_for(order)
    if square is None:
        return -1
    if not _is_normal_magic_square(square):
        raise AssertionError("constructed square violates normal magic-square invariants")

    payload = bytearray((order,))
    for row in square:
        for value in row:
            payload.extend(struct.pack("<i", value))
    checksum = FNV_OFFSET
    for byte in payload:
        checksum = ((checksum ^ byte) * FNV_PRIME) & MASK64
    return checksum & MASK63
