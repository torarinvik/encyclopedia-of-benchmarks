"""Direct per-cell reference for the bounded synchronous forest-fire profile."""

from __future__ import annotations

import struct

MAX_ROWS = 8
MAX_COLS = 8
MAX_STEPS = 8
MAX_DENOMINATOR = 10_000
MAX_CELLS = MAX_ROWS * MAX_COLS
MAX_VALID_INPUT_LENGTH = 6 + MAX_CELLS + 2 * MAX_STEPS * MAX_CELLS
MAX_PARSEABLE_INPUT_LENGTH = MAX_VALID_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (1 + 3 * MAX_STEPS + MAX_CELLS)
WORKSPACE_BYTES = 192


def _decode(values: list[int], length: int) -> tuple[int, int, int, int, int, int, list[int], list[int], list[int]] | None:
    if not 1 <= length <= MAX_PARSEABLE_INPUT_LENGTH or length != len(values) or length < 6:
        return None
    if any(type(value) is not int or not -(1 << 63) <= value < (1 << 63) for value in values):
        return None
    rows, cols, steps, denominator, grow_limit, lightning_limit = values[:6]
    if not 1 <= rows <= MAX_ROWS or not 1 <= cols <= MAX_COLS:
        return None
    if not 0 <= steps <= MAX_STEPS or denominator != MAX_DENOMINATOR:
        return None
    if not 0 <= grow_limit <= denominator or not 0 <= lightning_limit <= denominator:
        return None
    cells = rows * cols
    if length != 6 + cells + 2 * steps * cells:
        return None
    board = values[6 : 6 + cells]
    if any(state not in (0, 1, 2) for state in board):
        return None
    for row in range(rows):
        for col in range(cols):
            if (row == 0 or row + 1 == rows or col == 0 or col + 1 == cols) and board[row * cols + col] != 0:
                return None
    split = 6 + cells
    growth = values[split : split + steps * cells]
    lightning = values[split + steps * cells :]
    if any(not 0 <= draw < denominator for draw in growth + lightning):
        return None
    return rows, cols, steps, denominator, grow_limit, lightning_limit, board, growth, lightning


def _simulate(rows: int, cols: int, steps: int, grow_limit: int, lightning_limit: int,
              board: list[int], growth: list[int], lightning: list[int]) -> list[int]:
    cells = rows * cols
    current = bytearray(board)
    counts: list[int] = []
    for step in range(steps):
        next_board = bytearray(cells)
        for row in range(rows):
            for col in range(cols):
                site = row * cols + col
                state = current[site]
                if row == 0 or row + 1 == rows or col == 0 or col + 1 == cols:
                    next_board[site] = 0
                    continue
                if state == 2:
                    next_board[site] = 0
                elif state == 0:
                    draw = growth[step * cells + site]
                    next_board[site] = 1 if draw < grow_limit else 0
                else:
                    burning_neighbor = False
                    for nr in range(max(0, row - 1), min(rows, row + 2)):
                        for nc in range(max(0, col - 1), min(cols, col + 2)):
                            if (nr != row or nc != col) and current[nr * cols + nc] == 2:
                                burning_neighbor = True
                    if burning_neighbor or lightning[step * cells + site] < lightning_limit:
                        next_board[site] = 2
                    else:
                        next_board[site] = 1
        current = next_board
        empty_count = current.count(0)
        tree_count = current.count(1)
        burning_count = current.count(2)
        counts.extend((empty_count, tree_count, burning_count))
    return [steps, *counts, *current]


def expected_output(
    input_values: list[int],
    output_capacity: int | None = None,
    output_is_null: bool = False,
    input_is_null: bool = False,
    input_length: int | None = None,
) -> tuple[int, bytes]:
    if type(input_is_null) is not bool or input_is_null or not isinstance(input_values, (list, tuple)):
        return -1, b""
    length = len(input_values) if input_length is None else input_length
    if type(length) is not int:
        return -1, b""
    decoded = _decode(list(input_values), length)
    if decoded is None:
        return -1, b""
    rows, cols, steps, _, grow_limit, lightning_limit, board, growth, lightning = decoded
    words = _simulate(rows, cols, steps, grow_limit, lightning_limit, board, growth, lightning)
    payload = b"".join(struct.pack("<q", word) for word in words)
    if type(output_is_null) is not bool or output_is_null:
        return -2, b""
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < len(payload)):
        return -2, b""
    return len(payload), payload
