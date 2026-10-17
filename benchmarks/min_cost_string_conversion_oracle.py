"""Independent oracle for the pinned F# minimum-cost string conversion tables."""

from __future__ import annotations

import struct

MIN_TEXT_LENGTH = 0
MAX_TEXT_LENGTH = 32
MIN_ASCII_BYTE = 0
MAX_ASCII_BYTE = 127
MIN_COST = -1000
MAX_COST = 1000
MAX_INPUT_VALUES = 6 + 2 * MAX_TEXT_LENGTH
MAX_ROWS = MAX_TEXT_LENGTH + 1
MAX_CELLS = MAX_ROWS * MAX_ROWS
MAX_OUTPUT_BYTES = 8 * (4 + 4 * MAX_CELLS)
OP_INITIAL = 0
OP_COPY = 1
OP_REPLACE = 2
OP_DELETE = 3
OP_INSERT = 4
I64_MIN = -(1 << 63)
I64_MAX = (1 << 63) - 1


def expected_output(values: list[int] | tuple[int, ...] | None,
                    capacity: int | None = None) -> tuple[int, bytes]:
    """Return serialized cost and operation tables for the packed input."""
    if values is None or not isinstance(values, (list, tuple)):
        return -1, b""
    if (not 6 <= len(values) <= MAX_INPUT_VALUES
            or any(type(value) is not int or not I64_MIN <= value <= I64_MAX
                   for value in values)):
        return -1, b""
    src_len = values[0]
    if not MIN_TEXT_LENGTH <= src_len <= MAX_TEXT_LENGTH or len(values) < 1 + src_len + 1 + 4:
        return -1, b""
    src_start = 1
    dst_len_pos = src_start + src_len
    dst_len = values[dst_len_pos]
    expected_len = 6 + src_len + dst_len
    if not MIN_TEXT_LENGTH <= dst_len <= MAX_TEXT_LENGTH or len(values) != expected_len:
        return -1, b""
    src = values[src_start:dst_len_pos]
    dst_start = dst_len_pos + 1
    dst = values[dst_start:dst_start + dst_len]
    costs = values[dst_start + dst_len:]
    if len(costs) != 4 or any(not MIN_ASCII_BYTE <= byte <= MAX_ASCII_BYTE
                              for byte in (*src, *dst)):
        return -1, b""
    copy_cost, replace_cost, delete_cost, insert_cost = costs
    if any(not MIN_COST <= cost <= MAX_COST for cost in costs):
        return -1, b""

    rows, cols = src_len + 1, dst_len + 1
    table = [[0] * cols for _ in range(rows)]
    ops = [[(OP_INITIAL, 0, 0) for _ in range(cols)] for _ in range(rows)]
    for j in range(1, cols):
        table[0][j] = table[0][j - 1] + insert_cost
        ops[0][j] = (OP_INSERT, 0, dst[j - 1])
    for i in range(1, rows):
        table[i][0] = table[i - 1][0] + delete_cost
        ops[i][0] = (OP_DELETE, src[i - 1], 0)
    for i in range(1, rows):
        for j in range(1, cols):
            a, b = src[i - 1], dst[j - 1]
            if a == b:
                best = table[i - 1][j - 1] + copy_cost
                op = (OP_COPY, a, 0)
            else:
                best = table[i - 1][j - 1] + replace_cost
                op = (OP_REPLACE, a, b)
            deletion = table[i - 1][j] + delete_cost
            if deletion < best:
                best, op = deletion, (OP_DELETE, a, 0)
            insertion = table[i][j - 1] + insert_cost
            if insertion < best:
                best, op = insertion, (OP_INSERT, 0, b)
            table[i][j], ops[i][j] = best, op

    output = bytearray()
    pack = lambda value: struct.pack("<q", value)
    output += pack(rows) + pack(cols)
    for row in table:
        for value in row:
            output += pack(value)
    output += pack(rows) + pack(cols)
    for row in ops:
        for op_code, char_a, char_b in row:
            output += pack(op_code) + pack(char_a) + pack(char_b)
    if capacity is not None and (type(capacity) is not int or capacity < len(output)):
        return -2, b""
    return len(output), bytes(output)
