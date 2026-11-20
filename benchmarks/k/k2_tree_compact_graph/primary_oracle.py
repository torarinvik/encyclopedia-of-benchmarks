"""Packed T/L k²-tree reference with rank-prefix navigation."""

from __future__ import annotations

import struct
from collections.abc import Sequence

MAX_N = 32
MAX_Q = 128
MAX_INPUT_LENGTH = 2 + MAX_N + 3 * MAX_Q
MAX_PARSEABLE_INPUT_LENGTH = MAX_INPUT_LENGTH + 1
MAX_OUTPUT_BYTES = 8 * (MAX_Q + 1)
MAX_WORKSPACE_BYTES = 4096
INVALID_RESULT = -1
OUTPUT_ERROR = -2
MAX_T_BITS = 340
MAX_L_BITS = 1024
MAX_T_BYTES = (MAX_T_BITS + 7) // 8
MAX_L_BYTES = (MAX_L_BITS + 7) // 8


def _bit_get(bits: bytearray, index: int) -> int:
    return (bits[index >> 3] >> (index & 7)) & 1


def _bit_set(bits: bytearray, index: int) -> None:
    bits[index >> 3] |= 1 << (index & 7)


def _parse(values: Sequence[int] | None, input_length: int | None,
           input_is_null: bool):
    if (type(input_is_null) is not bool or input_is_null
            or not isinstance(values, (list, tuple))
            or not 2 <= len(values) <= MAX_PARSEABLE_INPUT_LENGTH
            or any(type(value) is not int or not -(1 << 63) <= value < (1 << 63)
                   for value in values)
            or input_length is not None
            and (type(input_length) is not int or input_length != len(values))):
        return None
    n = values[0]
    if type(n) is not int or not 1 <= n <= MAX_N or len(values) < n + 2:
        return None
    row_limit = (1 << n) - 1
    rows = tuple(values[1:1 + n])
    if any(type(mask) is not int or not 0 <= mask <= row_limit for mask in rows):
        return None
    q_index = n + 1
    q = values[q_index]
    if type(q) is not int or not 0 <= q <= MAX_Q:
        return None
    if len(values) != n + 2 + 3 * q:
        return None
    queries = []
    for offset in range(q_index + 1, len(values), 3):
        op, u, v = values[offset:offset + 3]
        if not 0 <= u < n:
            return None
        if op == 0:
            if not 0 <= v < n:
                return None
        elif op == 1:
            if v != 0:
                return None
        else:
            return None
        queries.append((op, u, v))
    return n, rows, q, tuple(queries)


def _next_power_height(n: int) -> tuple[int, int]:
    side = 2
    height = 1
    while side < n:
        side *= 2
        height += 1
    return side, height


def _block_nonempty(rows: tuple[int, ...], n: int, row_start: int,
                    col_start: int, side: int) -> bool:
    col_mask = ((1 << side) - 1) << col_start
    for row in range(row_start, row_start + side):
        if row < n and rows[row] & col_mask:
            return True
    return False


def _build(rows: tuple[int, ...], n: int):
    side, height = _next_power_height(n)
    t_bits = bytearray(MAX_T_BYTES)
    l_bits = bytearray(MAX_L_BYTES)
    current_rows = [0] * 256
    current_cols = [0] * 256
    next_rows = [0] * 256
    next_cols = [0] * 256
    current_rows[0] = 0
    current_cols[0] = 0
    current_count = 1
    t_length = 0
    l_length = 0
    current_side = side

    for level in range(1, height + 1):
        child_side = current_side // 2
        next_count = 0
        for parent in range(current_count):
            row_start = current_rows[parent]
            col_start = current_cols[parent]
            for quadrant in range(4):
                child_row = row_start + (quadrant // 2) * child_side
                child_col = col_start + (quadrant % 2) * child_side
                occupied = _block_nonempty(rows, n, child_row, child_col, child_side)
                if level < height:
                    if occupied:
                        _bit_set(t_bits, t_length)
                        next_rows[next_count] = child_row
                        next_cols[next_count] = child_col
                        next_count += 1
                    t_length += 1
                else:
                    if occupied:
                        _bit_set(l_bits, l_length)
                    l_length += 1
        if level < height:
            for i in range(next_count):
                current_rows[i] = next_rows[i]
                current_cols[i] = next_cols[i]
            current_count = next_count
            current_side = child_side

    rank_prefix = [0] * (t_length + 1)
    for i in range(t_length):
        rank_prefix[i + 1] = rank_prefix[i] + _bit_get(t_bits, i)
    return t_bits, l_bits, t_length, l_length, rank_prefix, height


def _contains(t_bits: bytearray, l_bits: bytearray, t_length: int,
              rank_prefix: list[int], height: int, u: int, v: int) -> bool:
    parent = -1
    row_start = 0
    col_start = 0
    side = 1 << height
    for _ in range(height):
        child_side = side // 2
        row_bit = int(u >= row_start + child_side)
        col_bit = int(v >= col_start + child_side)
        quadrant = 2 * row_bit + col_bit
        child_base = 0 if parent < 0 else 4 * rank_prefix[parent + 1]
        child = child_base + quadrant
        if row_bit:
            row_start += child_side
        if col_bit:
            col_start += child_side
        if child < t_length:
            if not _bit_get(t_bits, child):
                return False
            parent = child
        else:
            return bool(_bit_get(l_bits, child - t_length))
        side = child_side
    return False


def _run(values, input_length=None, input_is_null=False):
    parsed = _parse(values, input_length, input_is_null)
    if parsed is None:
        return None
    n, rows, q, queries = parsed
    t_bits, l_bits, t_length, _l_length, rank_prefix, height = _build(rows, n)
    output = [q]
    for op, u, v in queries:
        if op == 0:
            output.append(int(_contains(t_bits, l_bits, t_length, rank_prefix,
                                        height, u, v)))
        else:
            mask = 0
            for successor in range(n):
                if _contains(t_bits, l_bits, t_length, rank_prefix,
                             height, u, successor):
                    mask |= 1 << successor
            output.append(mask)
    return output


def expected_output(values: Sequence[int] | None, output_capacity=None,
                    output_is_null=False, input_is_null=False,
                    input_length=None):
    words = _run(values, input_length, input_is_null)
    if words is None:
        return INVALID_RESULT, b""
    payload = b"".join(struct.pack("<q", word) for word in words)
    if (type(output_is_null) is not bool or output_is_null
            or output_capacity is not None
            and (type(output_capacity) is not int or output_capacity < len(payload))):
        return OUTPUT_ERROR, b""
    return len(payload), payload
