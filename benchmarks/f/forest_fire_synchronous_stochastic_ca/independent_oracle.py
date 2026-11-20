"""Burning-neighbor-map reference for the bounded forest-fire profile."""

from __future__ import annotations

import struct

MAX_ROWS = 8
MAX_COLS = 8
MAX_STEPS = 8
MAX_DENOMINATOR = 10_000
MAX_CELLS = 64
MAX_VALID_INPUT_LENGTH = 6 + MAX_CELLS + 2 * MAX_STEPS * MAX_CELLS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + 3 * MAX_STEPS + MAX_CELLS)
WORKSPACE_BYTES = 192


def _checked(values: list[int], length: int):
    if length < 6 or length > MAX_PARSEABLE_INPUT_LENGTH or length != len(values):
        return None
    if any(type(value) is not int or value < -(1 << 63) or value >= (1 << 63) for value in values):
        return None
    rows, cols, steps, denominator, grow_limit, lightning_limit = values[:6]
    if not 1 <= rows <= 8 or not 1 <= cols <= 8 or not 0 <= steps <= 8:
        return None
    if denominator != MAX_DENOMINATOR or not 0 <= grow_limit <= denominator or not 0 <= lightning_limit <= denominator:
        return None
    cells = rows * cols
    if len(values) != 6 + cells + 2 * steps * cells:
        return None
    old = [values[6 + row * cols : 6 + (row + 1) * cols] for row in range(rows)]
    if any(value not in (0, 1, 2) for row in old for value in row):
        return None
    for row in range(rows):
        for col in range(cols):
            if (row == 0 or row == rows - 1 or col == 0 or col == cols - 1) and old[row][col] != 0:
                return None
    tape_start = 6 + cells
    growth = values[tape_start : tape_start + steps * cells]
    lightning = values[tape_start + steps * cells :]
    if any(value < 0 or value >= denominator for value in growth + lightning):
        return None
    return rows, cols, steps, grow_limit, lightning_limit, old, growth, lightning


def _result(rows: int, cols: int, steps: int, grow_limit: int, lightning_limit: int,
            board: list[list[int]], growth: list[int], lightning: list[int]) -> list[int]:
    flat_count = rows * cols
    history: list[int] = []
    for tick in range(steps):
        adjacent = [[False for _ in range(cols)] for _ in range(rows)]
        for r in range(rows):
            for c in range(cols):
                if board[r][c] == 2:
                    for rr in range(max(0, r - 1), min(rows, r + 2)):
                        for cc in range(max(0, c - 1), min(cols, c + 2)):
                            if (rr, cc) != (r, c):
                                adjacent[rr][cc] = True

        next_rows: list[list[int]] = []
        for r in range(rows):
            next_row: list[int] = []
            for c in range(cols):
                at = tick * flat_count + r * cols + c
                if r == 0 or r == rows - 1 or c == 0 or c == cols - 1:
                    next_row.append(0)
                    continue
                cell = board[r][c]
                if cell == 2:
                    next_row.append(0)
                elif cell == 1:
                    ignites = adjacent[r][c] or lightning[at] < lightning_limit
                    next_row.append(2 if ignites else 1)
                else:
                    next_row.append(1 if growth[at] < grow_limit else 0)
            next_rows.append(next_row)
        board = next_rows
        frequencies = [0, 0, 0]
        for row in board:
            for cell in row:
                frequencies[cell] += 1
        history.extend(frequencies)
    return [steps, *history, *(cell for row in board for cell in row)]


def expected_output(input_values, output_capacity=None, output_is_null=False,
                    input_is_null=False, input_length=None):
    if type(input_is_null) is not bool or input_is_null or not isinstance(input_values, (list, tuple)):
        return -1, b""
    length = len(input_values) if input_length is None else input_length
    if type(length) is not int:
        return -1, b""
    parsed = _checked(list(input_values), length)
    if parsed is None:
        return -1, b""
    rows, cols, steps, grow_limit, lightning_limit, board, growth, lightning = parsed
    payload = b"".join(struct.pack("<q", word) for word in _result(
        rows, cols, steps, grow_limit, lightning_limit, board, growth, lightning))
    if type(output_is_null) is not bool or output_is_null:
        return -2, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < len(payload)):
        return -2, b""
    return len(payload), payload
