"""Reference DP oracle for a bounded fixed-record table partition profile."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_INPUT = 66
OUTPUT_BYTES = 24


def _rle_pair_cost(table: Sequence[int], rows: int, cols: int,
                   begin: int, end: int) -> int:
    runs = 0
    have_previous = False
    previous = 0
    for row in range(rows):
        for column in range(begin, end):
            value = table[row * cols + column]
            if not have_previous or value != previous:
                runs += 1
            previous = value
            have_previous = True
    return 2 * runs


def _payload(words: list[int]) -> bytes:
    return b"".join(struct.pack("<q", word) for word in words)


def expected_output(values: Sequence[int] | None, output_capacity: int | None = None,
                    output_is_null: bool = False, input_is_null: bool = False,
                    input_length: int | None = None) -> tuple[int, bytes]:
    if (type(output_is_null) is not bool or type(input_is_null) is not bool
            or input_is_null or not isinstance(values, (tuple, list))
            or len(values) < 3 or len(values) > MAX_INPUT
            or input_length is not None and
                (type(input_length) is not int or input_length != len(values))
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)):
        return -1, b""
    rows, cols = values[:2]
    if not 1 <= rows <= 8 or not 1 <= cols <= 8 or len(values) != 2 + rows * cols:
        return -1, b""
    table = values[2:]
    if any(value < 0 or value > 15 for value in table):
        return -1, b""

    cost = [0] + [1 << 60] * cols
    previous = [0] * (cols + 1)
    for end in range(1, cols + 1):
        for start in range(end):
            candidate = cost[start] + _rle_pair_cost(table, rows, cols, start, end)
            # Ascending starts plus strict comparison specify smaller-cut tie priority.
            if candidate < cost[end]:
                cost[end] = candidate
                previous[end] = start
    groups = 0
    cut_mask = 0
    end = cols
    while end:
        start = previous[end]
        if start:
            cut_mask |= 1 << (start - 1)
        groups += 1
        end = start
    payload = _payload([cost[cols], groups, cut_mask])
    if output_capacity is not None and (type(output_capacity) is not int or output_capacity < 0):
        return -1, b""
    if output_is_null or (output_capacity is not None and output_capacity < OUTPUT_BYTES):
        return -2, b""
    return OUTPUT_BYTES, payload
