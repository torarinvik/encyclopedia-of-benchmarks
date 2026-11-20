"""Synchronous batch-toppling reference for Abelian sandpile stabilization."""

from __future__ import annotations

from collections.abc import Sequence

from .primary_oracle import (
    INVALID_RESULT,
    MAX_COLS,
    MAX_HEIGHT,
    MAX_PARSEABLE_INPUT_LENGTH,
    MAX_ROWS,
    MAX_TOPPLES,
)


def _read_frame(values: Sequence[int] | None, input_is_null: bool,
                input_length: int | None) -> tuple[int, int, list[int]] | None:
    if type(input_is_null) is not bool or input_is_null:
        return None
    if not isinstance(values, (list, tuple)):
        return None
    if not (2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH):
        return None
    if any(type(item) is not int or item < -(1 << 63) or item >= (1 << 63)
           for item in values):
        return None
    declared = len(values) if input_length is None else input_length
    if type(declared) is not int or declared != len(values):
        return None
    height, width = values[0], values[1]
    if height not in range(1, MAX_ROWS + 1) or width not in range(1, MAX_COLS + 1):
        return None
    area = height * width
    if area + 2 != len(values):
        return None
    board = list(values[2:])
    if any(chips not in range(MAX_HEIGHT + 1) for chips in board):
        return None
    return height, width, board


def _pack_low_order_first(board: list[int]) -> int:
    encoded = 0
    multiplier = 1
    for index in range(len(board)):
        encoded = encoded + board[index] * multiplier
        multiplier = multiplier * 4
    return encoded


def _round_synchronous(rows: int, cols: int, initial: list[int]) -> list[int] | None:
    board = initial[:]
    topplings = 0
    while True:
        following = [chips - 4 * (chips // 4) for chips in board]
        changed = False
        for source in range(rows * cols):
            batch = board[source] // 4
            if batch == 0:
                continue
            changed = True
            topplings += batch
            if topplings > MAX_TOPPLES:
                return None
            y, x = divmod(source, cols)
            if y > 0:
                following[source - cols] += batch
            if x + 1 < cols:
                following[source + 1] += batch
            if y + 1 < rows:
                following[source + cols] += batch
            if x > 0:
                following[source - 1] += batch
        if not changed:
            return following
        board = following


def expected_result(values: Sequence[int] | None, input_is_null: bool = False,
                    input_length: int | None = None) -> int:
    """Return the same Abelian stabilization via synchronous legal batches."""
    frame = _read_frame(values, input_is_null, input_length)
    if frame is None:
        return INVALID_RESULT
    rows, cols, cells = frame
    stable = _round_synchronous(rows, cols, cells)
    if stable is None:
        return INVALID_RESULT
    return _pack_low_order_first(stable)
