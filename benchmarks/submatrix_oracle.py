"""Bounded row-major contract for extracting a matrix subrectangle."""
from __future__ import annotations

MAX_INPUT_LENGTH = 70
INVALID_RESULT = -1
MASK64 = (1 << 64) - 1
FNV_OFFSET = 0xCBF29CE484222325
FNV_PRIME = 0x100000001B3


def _feed(h: int, value: int) -> int:
    for byte in int(value).to_bytes(8, "little", signed=True):
        h = ((h ^ byte) * FNV_PRIME) & MASK64
    return h


def expected_result(values: list[int]) -> int:
    if len(values) < 6:
        return INVALID_RESULT
    rows, cols, row_start, col_start, out_rows, out_cols = values[:6]
    if not (1 <= rows <= 8 and 1 <= cols <= 8 and rows * cols <= 64):
        return INVALID_RESULT
    if len(values) != 6 + rows * cols:
        return INVALID_RESULT
    if not (0 <= row_start <= rows and 0 <= col_start <= cols):
        return INVALID_RESULT
    if not (0 <= out_rows <= rows and 0 <= out_cols <= cols):
        return INVALID_RESULT
    if row_start + out_rows > rows or col_start + out_cols > cols:
        return INVALID_RESULT
    cells = values[6:]
    if any(x < -2_147_483_648 or x > 2_147_483_647 for x in cells):
        return INVALID_RESULT
    h = _feed(FNV_OFFSET, out_rows)
    h = _feed(h, out_cols)
    for r in range(out_rows):
        base = (row_start + r) * cols + col_start
        for c in range(out_cols):
            h = _feed(h, cells[base + c])
    return h if h < (1 << 63) else h - (1 << 64)
